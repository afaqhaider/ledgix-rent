import { randomInt, randomUUID } from "node:crypto";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { getAuth } from "firebase-admin/auth";
import { DocumentData, FieldValue, Firestore, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

/**
 * Landlord <-> tenant connection.
 *
 *  - invites/{code}                                  server-only invite codes
 *  - landlords/{ll}/tenants/{tid}.appUid             the tenant's auth uid once joined
 *  - tenantLinks/{uid}/landlords/{ll}                {status active|former, tenantIds, since, endedAt}
 *  - tenantViews/{uid}/{landlords|properties|leases|payments|documents|inspections|holdRequests}/{id}
 *        what the tenant may read; rebuilt from landlords/{ll}/** by onLandlordDataWritten.
 *        Mirrors buildTenantView in lib/features/tenant_portal/domain/tenant_view.dart.
 *
 * Only these functions (Admin SDK) write links, views and invites.
 */

const ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"; // no 0/O, 1/I/L
const INVITE_DAYS = 30;
const MAX_INVITES_PER_HOUR = 50;
const VIEW_COLLECTIONS = ["properties", "leases", "payments", "documents", "inspections", "holdRequests"] as const;
const SOURCE_COLLECTIONS = new Set(["properties", "tenants", "leases", "payments", "profile", "inspections", "holdRequests"]);
const MAX_HOLD_DAYS = 90; // mirrors maxHoldDays in lib/features/holds/domain/hold_request.dart

const db = (): Firestore => getFirestore();
const text = (v: unknown): string => (typeof v === "string" ? v.trim() : "");
const normaliseCode = (c: unknown): string => text(c).toUpperCase().replace(/[^A-Z0-9]/g, "");
const digits = (v: unknown): string => text(v).replace(/\D/g, "");
const day = (v: unknown): string => String(v ?? "").slice(0, 10);

function refuse(reason: string, message: string): never {
  throw new HttpsError("failed-precondition", message, { reason });
}

function newCode(): string {
  let s = "";
  for (let i = 0; i < 8; i++) s += ALPHABET[randomInt(ALPHABET.length)];
  return s;
}

/** GST "today" as yyyy-MM-dd. */
export function todayGst(): string {
  return new Date(Date.now() + 4 * 3600 * 1000).toISOString().slice(0, 10);
}

// ---------------------------------------------------------------------------
// Invites
// ---------------------------------------------------------------------------

/** Landlord: new invite code for one of their tenants (replaces any unused one). */
export const createTenantInvite = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  const tenantId = text(req.data?.tenantId);
  const leaseId = text(req.data?.leaseId) || null;
  if (!tenantId) throw new HttpsError("invalid-argument", "tenantId is required.");

  const tenantRef = db().doc(`landlords/${uid}/tenants/${tenantId}`);
  if (!(await tenantRef.get()).exists) throw new HttpsError("not-found", "Tenant not found.");

  // Simple per-landlord rate limit.
  const quotaRef = db().doc(`inviteQuota/${uid}`);
  await db().runTransaction(async (t) => {
    const q = await t.get(quotaRef);
    const now = Date.now();
    const start = q.exists ? (q.get("windowStart") as number) : 0;
    const count = q.exists && now - start < 3600_000 ? (q.get("count") as number) : 0;
    if (count >= MAX_INVITES_PER_HOUR) throw new HttpsError("resource-exhausted", "Too many invite codes. Try again later.");
    t.set(quotaRef, { windowStart: count === 0 ? now : start, count: count + 1 });
  });

  const old = await db().collection("invites")
    .where("landlordUid", "==", uid).where("tenantId", "==", tenantId).where("usedAt", "==", null).get();
  const batch = db().batch();
  old.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();

  const expiresAt = new Date(Date.now() + INVITE_DAYS * 86400_000);
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = newCode();
    try {
      await db().doc(`invites/${code}`).create({
        landlordUid: uid, tenantId, leaseId,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromDate(expiresAt),
        usedAt: null,
      });
      await tenantRef.set({ inviteCode: code, inviteExpiresAt: expiresAt.toISOString() }, { merge: true });
      return { code, expiresAt: expiresAt.toISOString() };
    } catch (e) {
      if ((e as { code?: number }).code !== 6) throw e; // 6 = ALREADY_EXISTS: try another code
    }
  }
  throw new HttpsError("internal", "Could not create a code. Try again.");
});

/** Tenant: redeem a code; links them to that landlord's tenant record. */
export const redeemTenantInvite = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  const code = normaliseCode(req.data?.code);
  if (code.length !== 8) refuse("invalid", "That code isn't valid.");

  const inviteRef = db().doc(`invites/${code}`);
  const { landlordUid, tenantId } = await db().runTransaction(async (t) => {
    const inv = await t.get(inviteRef);
    if (!inv.exists) refuse("invalid", "That code isn't valid.");
    if (inv.get("usedAt")) refuse("used", "That code has already been used.");
    if ((inv.get("expiresAt") as Timestamp).toMillis() < Date.now()) refuse("expired", "That code has expired.");
    const ll = inv.get("landlordUid") as string;
    const tid = inv.get("tenantId") as string;
    if (ll === uid) refuse("ownCode", "You created this code.");

    const tenantRef = db().doc(`landlords/${ll}/tenants/${tid}`);
    const tenant = await t.get(tenantRef);
    if (!tenant.exists) refuse("invalid", "That code isn't valid.");
    const linked = tenant.get("appUid");
    if (linked && linked !== uid) refuse("alreadyLinked", "This tenant record is linked to another account.");

    // The same account may join several records of one landlord only if they are the same person.
    const others = await t.get(db().collection(`landlords/${ll}/tenants`).where("appUid", "==", uid));
    for (const o of others.docs) {
      if (o.id === tid) continue;
      const a = digits(o.get("emiratesIdNo"));
      const b = digits(tenant.get("emiratesIdNo"));
      if (!a || a !== b) refuse("alreadyLinked", "This account is already linked to another tenant of this landlord.");
    }

    // All reads before any write (Firestore transactions).
    const linkRef = db().doc(`tenantLinks/${uid}/landlords/${ll}`);
    const link = await t.get(linkRef);
    t.update(tenantRef, { appUid: uid, inviteCode: FieldValue.delete(), inviteExpiresAt: FieldValue.delete() });
    t.update(inviteRef, { usedAt: FieldValue.serverTimestamp(), usedBy: uid });
    t.set(linkRef, {
      landlordUid: ll,
      status: "active",
      tenantIds: FieldValue.arrayUnion(tid),
      since: link.exists ? link.get("since") : new Date().toISOString(),
    }, { merge: true });
    return { landlordUid: ll, tenantId: tid };
  });

  await rebuildTenantView(landlordUid, uid);
  return { landlordUid, tenantId };
});

/** Tenant: remove a former landlord from their app. */
export const removeLandlordLink = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  const ll = text(req.data?.landlordUid);
  const linkRef = db().doc(`tenantLinks/${uid}/landlords/${ll}`);
  const link = await linkRef.get();
  if (!link.exists) return { removed: false };
  if (link.get("status") !== "former") refuse("active", "Only former landlords can be removed.");
  await unlinkTenant(ll, uid);
  return { removed: true };
});

/** Tenant: maintenance request for one of their properties. */
export const createTenantMaintenanceRequest = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  const ll = text(req.data?.landlordUid);
  const propertyId = text(req.data?.propertyId);
  const title = text(req.data?.title).slice(0, 200);
  if (!ll || !propertyId || !title) throw new HttpsError("invalid-argument", "landlordUid, propertyId and title are required.");
  const link = await db().doc(`tenantLinks/${uid}/landlords/${ll}`).get();
  const prop = await db().doc(`tenantViews/${uid}/properties/${propertyId}`).get();
  if (!link.exists || link.get("status") !== "active" || prop.get("landlordUid") !== ll) {
    throw new HttpsError("permission-denied", "You can only raise requests for your current properties.");
  }
  const photos = Array.isArray(req.data?.photos)
    ? (req.data.photos as unknown[]).map(String).filter((p) => p.startsWith("https://")).slice(0, 10)
    : [];
  const id = randomUUID();
  await db().doc(`landlords/${ll}/maintenanceTickets/${id}`).set({
    id, propertyId, title,
    description: text(req.data?.description).slice(0, 4000),
    raisedBy: "tenant",
    raisedByUid: uid,
    photos, videos: [],
    priority: "medium", urgency: "medium", status: "open", category: "other",
    cost: 0, visitRequired: false, timeSlots: [], accessNotes: "", landlordNote: "",
    shareTenantContact: false,
    createdAt: new Date().toISOString(),
  });
  await notify(await landlordTokens(ll), {
    title: "New maintenance request",
    body: `${prop.get("name") ?? "A property"}: ${title}`,
  });
  return { id };
});

/**
 * Tenant: ask the landlord to hold one of their payments until a later date.
 * Mirrors checkTenantHoldRequest in lib/features/holds/domain/hold_request.dart.
 * The payment itself is untouched until the landlord approves or declines.
 */
export const createTenantHoldRequest = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  const ll = text(req.data?.landlordUid);
  const paymentId = text(req.data?.paymentId);
  const requested = day(req.data?.requestedDate);
  const reason = text(req.data?.reason).slice(0, 1000);
  const note = text(req.data?.note).slice(0, 2000);
  if (!ll || !paymentId || !/^\d{4}-\d{2}-\d{2}$/.test(requested)) {
    throw new HttpsError("invalid-argument", "landlordUid, paymentId and requestedDate (yyyy-MM-dd) are required.");
  }

  const link = await db().doc(`tenantLinks/${uid}/landlords/${ll}`).get();
  if (!link.exists || link.get("status") !== "active") refuse("notAllowed", "You can only ask your current landlords.");
  const tenantIds = (link.get("tenantIds") as string[] | undefined) ?? [];
  const pay = await db().doc(`landlords/${ll}/payments/${paymentId}`).get();
  if (!pay.exists) refuse("notAllowed", "Payment not found.");
  const lease = await db().doc(`landlords/${ll}/leases/${pay.get("leaseId")}`).get();
  if (!lease.exists || !tenantIds.includes(lease.get("tenantId"))) refuse("notAllowed", "That isn't one of your payments.");
  // Make sure the link is current (not a stale tenantIds entry).
  const tenant = await db().doc(`landlords/${ll}/tenants/${lease.get("tenantId")}`).get();
  if (tenant.get("appUid") !== uid) refuse("notAllowed", "That isn't one of your payments.");

  const status = text(pay.get("status")) || "pending";
  if (status !== "pending" && status !== "onHold") refuse("notAllowed", "This payment can't be put on hold.");
  const holds = db().collection(`landlords/${ll}/holdRequests`);
  const open = await holds.where("paymentId", "==", paymentId).where("status", "==", "pending").limit(1).get();
  if (!open.empty) refuse("alreadyOpen", "There's already a request for this payment.");
  if (!reason) refuse("reasonRequired", "Please give a reason.");
  const due = day(pay.get("dueDate"));
  if (requested <= due) refuse("dateNotAfterDue", "Pick a date after the due date.");
  const days = (Date.parse(requested) - Date.parse(due)) / 86400_000;
  if (days > MAX_HOLD_DAYS) refuse("dateTooFar", `Pick a date within ${MAX_HOLD_DAYS} days of the due date.`);

  const id = randomUUID();
  await holds.doc(id).set({
    id, paymentId,
    requestedBy: "tenant", source: "tenant", requestedByUid: uid,
    tenantId: lease.get("tenantId"), leaseId: pay.get("leaseId"),
    reason, note, response: "",
    originalDate: pay.get("dueDate"),
    requestedDate: `${requested}T00:00:00.000`,
    status: "pending",
    createdAt: new Date().toISOString(),
  });

  const props = lease.get("propertyId") ? await db().doc(`landlords/${ll}/properties/${lease.get("propertyId")}`).get() : null;
  await notify(await landlordTokens(ll), {
    title: "Hold request",
    body: `${props?.get("name") ?? "A tenant"}: AED ${pay.get("amount")} due ${due}, asks to move it to ${requested}.`,
  }).catch(() => undefined);
  return { id };
});

// ---------------------------------------------------------------------------
// Read model
// ---------------------------------------------------------------------------

/** Keeps tenantViews in sync whenever a landlord's data changes. */
export const onLandlordDataWritten = onDocumentWritten("landlords/{ll}/{col}/{docId}", async (event) => {
  const { ll, col } = event.params;
  if (!SOURCE_COLLECTIONS.has(col)) return;
  const uids = new Set<string>();
  const before = event.data?.before?.data();
  if (col === "tenants" && before?.appUid) uids.add(before.appUid as string); // record deleted / unlinked
  const linked = await db().collection(`landlords/${ll}/tenants`).where("appUid", "!=", null).get();
  linked.docs.forEach((d) => uids.add(d.get("appUid") as string));
  for (const uid of uids) await rebuildTenantView(ll, uid);

  if (col === "payments") await alertPaymentChange(ll, before, event.data?.after?.data());
  if (col === "holdRequests") await alertHoldDecision(ll, before, event.data?.after?.data());
});

/** Rebuilds everything [uid] sees of landlord [ll] (idempotent). */
export async function rebuildTenantView(ll: string, uid: string): Promise<void> {
  const base = db().collection("landlords").doc(ll);
  const [profileSnap, tenantsSnap, leasesSnap, propsSnap, paysSnap, inspSnap, holdSnap] = await Promise.all([
    base.collection("profile").limit(1).get(),
    base.collection("tenants").get(),
    base.collection("leases").get(),
    base.collection("properties").get(),
    base.collection("payments").get(),
    base.collection("inspections").get(),
    base.collection("holdRequests").get(),
  ]);
  const tenantIds = tenantsSnap.docs.filter((d) => d.get("appUid") === uid).map((d) => d.id);
  const linkRef = db().doc(`tenantLinks/${uid}/landlords/${ll}`);
  if (tenantIds.length === 0) {
    await clearView(ll, uid);
    await linkRef.delete();
    return;
  }

  const today = todayGst();
  const myLeases = leasesSnap.docs.map((d) => ({ ...d.data(), id: d.id }) as DocumentData)
    .filter((x) => tenantIds.includes(x.tenantId))
    .sort((a, b) => day(a.startDate).localeCompare(day(b.startDate)));
  const leaseIds = new Set(myLeases.map((x) => x.id as string));
  const propertyOfLease = new Map(myLeases.map((x) => [x.id as string, x.propertyId as string]));
  const props = new Map(propsSnap.docs.map((d) => [d.id, d.data()]));
  const nameOf = (pid: string) => (props.get(pid)?.name as string) ?? "";
  const current = myLeases.some((x) => x.status === "active" && day(x.endDate) >= today);
  const status = myLeases.length === 0 || current ? "active" : "former";

  const docs: Record<string, Map<string, DocumentData>> = {};
  for (const c of VIEW_COLLECTIONS) docs[c] = new Map();

  for (const pid of new Set(myLeases.map((x) => x.propertyId as string))) {
    const p = props.get(pid);
    if (!p) continue;
    const mine = myLeases.filter((x) => x.propertyId === pid);
    docs.properties.set(pid, {
      landlordUid: ll, id: pid, name: p.name ?? "", type: p.type ?? "", address: p.address ?? "",
      community: p.community ?? "", titleDeedNo: p.titleDeedNo ?? "", dewaPremiseNo: p.dewaPremiseNo ?? "",
      dewaAccountNo: p.dewaAccountNo ?? "", mollakUnitRef: p.mollakUnitRef ?? "", hoaName: p.hoaName ?? "",
      hoaPhone: p.hoaPhone ?? "", agreementAmount: mine.length ? mine[mine.length - 1].annualRent ?? null : null,
      leaseIds: mine.map((x) => x.id),
    });
    addDocs(docs.documents, ll, "property", pid, pid, p.documents);
  }
  for (const x of myLeases) {
    docs.leases.set(x.id, {
      landlordUid: ll, id: x.id, propertyId: x.propertyId, propertyName: nameOf(x.propertyId),
      startDate: x.startDate, endDate: x.endDate, annualRent: x.annualRent ?? 0,
      securityDeposit: x.securityDeposit ?? 0, numberOfCheques: x.numberOfCheques ?? 1,
      paymentMethod: x.paymentMethod ?? "cheque", ejariNo: x.ejariNo ?? "", status: x.status ?? "active",
    });
    addDocs(docs.documents, ll, "lease", x.id, x.propertyId, x.documents);
  }
  for (const t of tenantsSnap.docs.filter((d) => tenantIds.includes(d.id))) {
    addDocs(docs.documents, ll, "tenant", t.id, "", t.get("documents"));
  }
  for (const p of paysSnap.docs) {
    const x = p.data();
    if (!leaseIds.has(x.leaseId)) continue;
    const pid = propertyOfLease.get(x.leaseId) ?? "";
    docs.payments.set(p.id, {
      landlordUid: ll, id: p.id, leaseId: x.leaseId, propertyId: pid, propertyName: nameOf(pid),
      type: x.type ?? "cheque", amount: x.amount ?? 0, dueDate: x.dueDate, chequeNo: x.chequeNo ?? "",
      bankName: x.bankName ?? "", status: x.status ?? "pending",
      imageUrl: x.shareImage === false ? null : x.image ?? null,
    });
  }
  // The tenant's own hold requests and the landlord's answers.
  for (const h of holdSnap.docs) {
    const x = h.data();
    if (!docs.payments.has(x.paymentId)) continue;
    docs.holdRequests.set(h.id, {
      landlordUid: ll, id: h.id, paymentId: x.paymentId,
      originalDate: x.originalDate ?? null, requestedDate: x.requestedDate ?? null,
      reason: x.reason ?? "", note: x.note ?? "", status: x.status ?? "pending",
      response: x.response ?? "", createdAt: x.createdAt ?? null,
    });
  }
  const profile = profileSnap.docs[0]?.data() ?? {};
  const tenantName = (tid: string) => {
    const t = tenantsSnap.docs.find((d) => d.id === tid)?.data() ?? {};
    const parts = [t.firstName, t.middleName, t.lastName].filter((s) => typeof s === "string" && s.trim());
    return parts.length ? parts.join(" ") : text(t.name);
  };
  for (const i of inspSnap.docs) {
    if (!leaseIds.has(i.get("leaseId"))) continue;
    const x = i.data();
    const p = props.get(x.propertyId) ?? {};
    // InspectionView and its PDF read these names from the tenant's copy.
    docs.inspections.set(i.id, {
      ...x, id: i.id, landlordUid: ll,
      propertyName: p.name ?? "", address: p.address ?? "",
      tenantName: tenantName(x.tenantId), landlordName: profile.name ?? "",
    });
  }

  let email = text(profile.email);
  if (!email) email = (await getAuth().getUser(ll).catch(() => null))?.email ?? "";
  const link = await linkRef.get();
  const since = link.exists ? link.get("since") : new Date().toISOString();

  const writes: Array<(b: FirebaseFirestore.WriteBatch) => void> = [];
  const view = db().collection("tenantViews").doc(uid);
  writes.push((b) => b.set(view.collection("landlords").doc(ll), {
    landlordUid: ll, name: profile.name ?? "", email, phone: profile.phone ?? "",
    emiratesIdNo: profile.emiratesIdNo ?? "", status, since,
  }));
  for (const c of VIEW_COLLECTIONS) {
    const existing = await view.collection(c).where("landlordUid", "==", ll).get();
    for (const d of existing.docs) if (!docs[c].has(d.id)) writes.push((b) => b.delete(d.ref));
    for (const [id, data] of docs[c]) writes.push((b) => b.set(view.collection(c).doc(id), data));
  }
  writes.push((b) => b.set(linkRef, {
    landlordUid: ll, status, tenantIds, since,
    endedAt: status === "former" ? (link.get("endedAt") ?? new Date().toISOString()) : null,
  }));
  await commitInChunks(writes);
}

function addDocs(out: Map<string, DocumentData>, ll: string, ownerType: string, ownerId: string, propertyId: string, list: unknown) {
  if (!Array.isArray(list)) return;
  list.forEach((d: DocumentData, i: number) => {
    if (d?.shared !== true || !text(d.url)) return;
    const id = `${ownerType}_${ownerId}_${i}`;
    out.set(id, { landlordUid: ll, id, ownerType, ownerId, propertyId, name: d.name ?? "", kind: d.kind ?? "other", url: d.url });
  });
}

async function clearView(ll: string, uid: string) {
  const view = db().collection("tenantViews").doc(uid);
  const writes: Array<(b: FirebaseFirestore.WriteBatch) => void> = [(b) => b.delete(view.collection("landlords").doc(ll))];
  for (const c of VIEW_COLLECTIONS) {
    const existing = await view.collection(c).where("landlordUid", "==", ll).get();
    existing.docs.forEach((d) => writes.push((b) => b.delete(d.ref)));
  }
  await commitInChunks(writes);
}

/** Removes the tenant <-> landlord connection on both sides. */
export async function unlinkTenant(ll: string, uid: string) {
  const records = await db().collection(`landlords/${ll}/tenants`).where("appUid", "==", uid).get();
  await Promise.all(records.docs.map((d) => d.ref.update({ appUid: FieldValue.delete() })));
  await clearView(ll, uid);
  await db().doc(`tenantLinks/${uid}/landlords/${ll}`).delete();
}

async function commitInChunks(writes: Array<(b: FirebaseFirestore.WriteBatch) => void>) {
  for (let i = 0; i < writes.length; i += 400) {
    const batch = db().batch();
    writes.slice(i, i + 400).forEach((w) => w(batch));
    await batch.commit();
  }
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

export async function userTokens(uid: string): Promise<string[]> {
  const u = await db().doc(`users/${uid}`).get();
  return (u.get("fcmTokens") as string[] | undefined) ?? [];
}

/** Landlord devices: users/{uid} plus the older landlords/{uid} field. */
export async function landlordTokens(ll: string): Promise<string[]> {
  const legacy = ((await db().doc(`landlords/${ll}`).get()).get("fcmTokens") as string[] | undefined) ?? [];
  return [...new Set([...legacy, ...(await userTokens(ll))])];
}

export async function notify(tokens: string[], notification: { title: string; body: string }) {
  if (tokens.length === 0) return;
  await getMessaging().sendEachForMulticast({ tokens, notification });
}

/** Tenants' auth uids on a lease (via its tenant record). */
export async function tenantUidsForLease(ll: string, leaseId: string): Promise<string[]> {
  const lease = await db().doc(`landlords/${ll}/leases/${leaseId}`).get();
  if (!lease.exists) return [];
  const tenant = await db().doc(`landlords/${ll}/tenants/${lease.get("tenantId")}`).get();
  const uid = tenant.get("appUid");
  return uid ? [uid as string] : [];
}

/** Tells the tenant when a cheque bounces or is put on hold. */
async function alertPaymentChange(ll: string, before: DocumentData | undefined, after: DocumentData | undefined) {
  if (!after || before?.status === after.status) return;
  if (after.status !== "bounced" && after.status !== "onHold") return;
  const body = after.status === "bounced"
    ? `Your payment of AED ${after.amount} due ${day(after.dueDate)} was returned. Please contact your landlord.`
    : `Your payment of AED ${after.amount} due ${day(after.dueDate)} is on hold.`;
  for (const uid of await tenantUidsForLease(ll, after.leaseId)) {
    await notify(await userTokens(uid), { title: after.status === "bounced" ? "Payment bounced" : "Payment on hold", body });
  }
}

/** Tells the tenant when the landlord approves or declines their hold request. */
async function alertHoldDecision(ll: string, before: DocumentData | undefined, after: DocumentData | undefined) {
  if (!after || before?.status !== "pending" || after.status === "pending") return;
  if (after.status !== "approved" && after.status !== "rejected") return;
  const uids = after.requestedByUid ? [after.requestedByUid as string] : await tenantUidsForLease(ll, after.leaseId);
  const approved = after.status === "approved";
  const body = approved
    ? `Your landlord approved moving your payment to ${day(after.requestedDate)}.`
    : `Your landlord declined your hold request${text(after.response) ? `: ${text(after.response)}` : "."}`;
  for (const uid of uids) {
    await notify(await userTokens(uid), { title: approved ? "Hold approved" : "Hold declined", body }).catch(() => undefined);
  }
}
