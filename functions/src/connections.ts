import { randomInt, randomUUID } from "node:crypto";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { DocumentData, Firestore, getFirestore } from "firebase-admin/firestore";
import { landlordTokens, linkTenantRecord, notify } from "./tenants";

/**
 * Finding people by email or personal LedGix code, and connection requests
 * ("invitations") between landlords and tenants. Mirrors
 * lib/features/connections/domain/connection.dart.
 *
 *  - shareCodes/{LGX-XXXXXX}          {uid}            server-only
 *  - users/{uid}.shareCode                             server-written
 *  - connectionRequests/{id}          readable by fromUid / toUid, server-written
 *  - connectionQuota/{uid}_{kind}     rate limits      server-only
 *
 * Nothing links until the recipient accepts. Lookups reveal only whether an
 * account exists and its role (plus "that's you" / "already connected").
 */

const ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"; // no 0/O, 1/I/L
export const MAX_LOOKUPS_PER_HOUR = 30;
const MAX_REQUESTS_PER_HOUR = 30;

const db = (): Firestore => getFirestore();
const text = (v: unknown): string => (typeof v === "string" ? v.trim() : "");

function refuse(reason: string, message: string, code: "failed-precondition" | "not-found" | "permission-denied" = "failed-precondition"): never {
  throw new HttpsError(code, message, { reason });
}

function signedIn(uid: string | undefined): string {
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  return uid;
}

/** "lgx 7k3m9q" / "LGX-7K3M9Q" -> "LGX-7K3M9Q", or "" if it isn't a code. */
export function normaliseShareCode(input: unknown): string {
  const s = text(input).toUpperCase().replace(/[^A-Z0-9]/g, "");
  return new RegExp(`^LGX[${ALPHABET}]{6}$`).test(s) ? `LGX-${s.slice(3)}` : "";
}

async function quota(uid: string, kind: string, max: number): Promise<void> {
  const ref = db().doc(`connectionQuota/${uid}_${kind}`);
  await db().runTransaction(async (t) => {
    const q = await t.get(ref);
    const now = Date.now();
    const start = q.exists ? (q.get("windowStart") as number) : 0;
    const count = q.exists && now - start < 3600_000 ? (q.get("count") as number) : 0;
    if (count >= max) throw new HttpsError("resource-exhausted", "Too many checks. Try again later.", { reason: "rateLimited" });
    t.set(ref, { windowStart: count === 0 ? now : start, count: count + 1 });
  });
}

/** The account behind an email or LedGix code, or null. */
async function resolveTarget(data: DocumentData | undefined): Promise<string | null> {
  const email = text(data?.email).toLowerCase();
  if (email) return (await getAuth().getUserByEmail(email).catch(() => null))?.uid ?? null;
  const code = normaliseShareCode(data?.code);
  if (!code) refuse("invalid", "Enter an email address or a LedGix code.");
  return ((await db().doc(`shareCodes/${code}`).get()).get("uid") as string | undefined) ?? null;
}

/** users/{uid}.role, else "landlord" for landlords who onboarded before roles, else null. */
async function roleOf(uid: string): Promise<string | null> {
  const role = (await db().doc(`users/${uid}`).get()).get("role");
  if (typeof role === "string") return role;
  return (await db().collection(`landlords/${uid}/profile`).limit(1).get()).empty ? null : "landlord";
}

async function isConnected(a: string, b: string): Promise<boolean> {
  const asLandlord = await db().collection(`landlords/${a}/tenants`).where("appUid", "==", b).limit(1).get();
  if (!asLandlord.empty) return true;
  return (await db().doc(`tenantLinks/${a}/landlords/${b}`).get()).exists;
}

async function displayName(uid: string): Promise<string> {
  const profile = (await db().collection(`landlords/${uid}/profile`).limit(1).get()).docs[0]?.get("name");
  if (text(profile)) return text(profile);
  return text((await db().doc(`users/${uid}`).get()).get("name"));
}

/** Background check while a landlord or tenant types an email or code. */
export const lookupAccount = onCall(async (req) => {
  const uid = signedIn(req.auth?.uid);
  await quota(uid, "lookup", MAX_LOOKUPS_PER_HOUR);
  const target = await resolveTarget(req.data);
  if (!target) return { exists: false };
  if (target === uid) return { exists: true, self: true };
  return { exists: true, linked: await isConnected(uid, target), role: await roleOf(target) };
});

/** The caller's personal LedGix code, created on first use. */
export const getMyShareCode = onCall(async (req) => {
  const uid = signedIn(req.auth?.uid);
  const userRef = db().doc(`users/${uid}`);
  const existing = text((await userRef.get()).get("shareCode"));
  if (existing) return { code: existing };
  for (let attempt = 0; attempt < 6; attempt++) {
    let code = "LGX-";
    for (let i = 0; i < 6; i++) code += ALPHABET[randomInt(ALPHABET.length)];
    try {
      await db().doc(`shareCodes/${code}`).create({ uid, createdAt: new Date().toISOString() });
      await userRef.set({ shareCode: code }, { merge: true });
      return { code };
    } catch (e) {
      if ((e as { code?: number }).code !== 6) throw e; // 6 = ALREADY_EXISTS: try another
    }
  }
  throw new HttpsError("internal", "Could not create a code. Try again.");
});

/** Fields of the tenant's own profile they may share with a landlord. */
async function sharedDetails(uid: string, email: string): Promise<DocumentData> {
  const u = (await db().doc(`users/${uid}`).get()).data() ?? {};
  return {
    name: text(u.name), email: text(u.email) || email, phone: text(u.phone),
    emiratesIdNo: text(u.emiratesIdNo), emiratesIdExpiry: u.emiratesIdExpiry ?? null,
    passportNo: text(u.passportNo), passportExpiry: u.passportExpiry ?? null,
  };
}

/**
 * Updates that copy [d] into the empty fields of a landlord's tenant record:
 * what the landlord typed always wins. Mirrors fillEmptyFields in
 * lib/features/connections/domain/connection.dart.
 */
export function fillEmptyTenantFields(record: DocumentData, d: DocumentData): DocumentData {
  const out: DocumentData = {};
  const empty = (k: string) => !text(record[k]);
  if (empty("firstName") && empty("lastName") && text(d.name)) {
    const p = text(d.name).split(/\s+/);
    out.firstName = p[0];
    out.lastName = p.length > 1 ? p[p.length - 1] : "";
    out.middleName = p.length > 2 ? p.slice(1, -1).join(" ") : "";
    if (empty("name")) out.name = text(d.name);
  }
  for (const k of ["email", "phone", "emiratesIdNo", "passportNo"]) if (empty(k) && text(d[k])) out[k] = text(d[k]);
  for (const k of ["emiratesIdExpiry", "passportExpiry"]) if (!record[k] && d[k]) out[k] = d[k];
  return out;
}

/** Landlord -> tenant (invite to a tenant record) or tenant -> landlord. */
export const sendConnectionRequest = onCall(async (req) => {
  const uid = signedIn(req.auth?.uid);
  const direction = text(req.data?.direction);
  if (direction !== "landlordToTenant" && direction !== "tenantToLandlord") refuse("invalid", "Unknown request type.");
  await quota(uid, "request", MAX_REQUESTS_PER_HOUR);
  const to = await resolveTarget(req.data);
  if (!to) refuse("notFound", "No LedGix Rent account uses that email or code.", "not-found");
  if (to === uid) refuse("self", "That's your own account.");

  const pending = db().collection("connectionRequests")
    .where("fromUid", "==", uid).where("toUid", "==", to).where("status", "==", "pending");
  const id = randomUUID();
  const typed = text(req.data?.email).toLowerCase() || normaliseShareCode(req.data?.code);
  const base = {
    id, fromUid: uid, toUid: to, direction, status: "pending", target: typed,
    createdAt: new Date().toISOString(), respondedAt: null,
  };

  if (direction === "landlordToTenant") {
    const tid = text(req.data?.tenantRecordId);
    if (!tid) refuse("invalid", "Choose the tenant to invite.");
    const record = await db().doc(`landlords/${uid}/tenants/${tid}`).get();
    if (!record.exists) refuse("invalid", "Tenant not found.");
    if (record.get("appUid")) refuse("alreadyLinked", "This tenant is already connected.");
    if (!(await pending.where("tenantRecordId", "==", tid).limit(1).get()).empty) {
      refuse("duplicate", "You've already invited them. Waiting for their answer.");
    }
    const leases = await db().collection(`landlords/${uid}/leases`).where("tenantId", "==", tid).get();
    const lease = leases.docs.sort((a, b) => String(a.get("startDate")).localeCompare(String(b.get("startDate")))).pop();
    const propertyName = lease
      ? text((await db().doc(`landlords/${uid}/properties/${lease.get("propertyId")}`).get()).get("name"))
      : "";
    await db().doc(`connectionRequests/${id}`).set({
      ...base, landlordUid: uid, tenantUid: to, tenantRecordId: tid, leaseId: lease?.id ?? null,
      propertyName, fromName: await displayName(uid), fromEmail: req.auth?.token.email ?? "", details: null,
    });
    await notify(await landlordTokens(to), {
      title: "Connection request",
      body: `${(await displayName(uid)) || "Your landlord"} wants to connect you${propertyName ? ` to ${propertyName}` : ""}.`,
    });
  } else {
    if ((await roleOf(to)) === "tenant") refuse("wrongRole", "That account belongs to a tenant, not a landlord.");
    if (!(await pending.limit(1).get()).empty) refuse("duplicate", "You've already sent them a request.");
    const email = text(req.auth?.token.email);
    const details = req.data?.shareDetails === true ? await sharedDetails(uid, email) : null;
    const name = text((await db().doc(`users/${uid}`).get()).get("name"));
    await db().doc(`connectionRequests/${id}`).set({
      ...base, landlordUid: to, tenantUid: uid, tenantRecordId: null, leaseId: null, propertyName: "",
      fromName: name, fromEmail: email, details,
    });
    await notify(await landlordTokens(to), {
      title: "New tenant connection request",
      body: `${name || email || "A tenant"} wants to connect with you on LedGix Rent.`,
    });
  }
  return { id };
});

/** Recipient accepts or declines; sender cancels. */
export const respondToConnectionRequest = onCall(async (req) => {
  const uid = signedIn(req.auth?.uid);
  const action = text(req.data?.action);
  const ref = db().doc(`connectionRequests/${text(req.data?.requestId)}`);
  const snap = await ref.get();
  if (!snap.exists) refuse("invalid", "That request no longer exists.");
  const r = snap.data() as DocumentData;
  if (r.status !== "pending") refuse("invalid", "That request has already been answered.");

  if (action === "cancel") {
    if (r.fromUid !== uid) refuse("notAllowed", "Only the sender can cancel.", "permission-denied");
    await ref.update({ status: "cancelled", respondedAt: new Date().toISOString() });
    return { status: "cancelled" };
  }
  if (r.toUid !== uid) refuse("notAllowed", "This request isn't for you.", "permission-denied");
  if (action === "decline") {
    await ref.update({ status: "declined", respondedAt: new Date().toISOString() });
    await notify(await landlordTokens(r.fromUid), { title: "Connection request declined", body: "Your request was declined." });
    return { status: "declined" };
  }
  if (action !== "accept") refuse("invalid", "Unknown action.");

  const ll = r.landlordUid as string;
  const tenantUid = r.tenantUid as string;
  const tid = r.direction === "landlordToTenant" ? text(r.tenantRecordId) : text(req.data?.tenantRecordId);
  if (!tid) refuse("invalid", "Choose which tenant this is.");
  const recordRef = db().doc(`landlords/${ll}/tenants/${tid}`);
  const record = await recordRef.get();
  if (!record.exists) refuse("invalid", "That tenant record no longer exists.");

  // The tenant's details reach the landlord's record only with their consent:
  // ticked when accepting an invitation, or when they sent their own request.
  const details = r.direction === "landlordToTenant"
    ? (req.data?.shareDetails === true ? await sharedDetails(tenantUid, "") : null)
    : (r.details as DocumentData | null);
  await linkTenantRecord(ll, tid, tenantUid);
  if (details) {
    const updates = fillEmptyTenantFields(record.data() ?? {}, details);
    if (Object.keys(updates).length) await recordRef.update(updates);
  }
  await ref.update({ status: "accepted", tenantRecordId: tid, respondedAt: new Date().toISOString() });
  await notify(await landlordTokens(r.fromUid), {
    title: "Connection request accepted",
    body: `${(await displayName(uid)) || "They"} accepted your request.`,
  });
  return { status: "accepted", tenantRecordId: tid };
});

/** Account deletion: drop the person's requests and share code. */
export async function deleteConnectionData(uid: string): Promise<void> {
  const [from, to, codes] = await Promise.all([
    db().collection("connectionRequests").where("fromUid", "==", uid).get(),
    db().collection("connectionRequests").where("toUid", "==", uid).get(),
    db().collection("shareCodes").where("uid", "==", uid).get(),
  ]);
  await Promise.all([...from.docs, ...to.docs, ...codes.docs].map((d) => d.ref.delete()));
  await Promise.all(["lookup", "request"].map((k) => db().doc(`connectionQuota/${uid}_${k}`).delete()));
}
