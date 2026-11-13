import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { randomUUID } from "node:crypto";
import { getStorage } from "firebase-admin/storage";

/**
 * Tenant actions on a landlord's move-in / move-out inspection
 * (landlords/{landlordUid}/inspections/{inspectionId}). Tenants never write
 * the landlord's data directly; each call checks that the caller is an
 * active tenant of that landlord (tenantLinks/{callerUid}/landlords/{landlordUid},
 * written by the invite flow) and is the tenant the inspection is for.
 * Mirrors lib/features/inspections/data/tenant_inspection_actions.dart.
 */

const MAX_COMMENT = 2000;

type Caller = { uid: string; landlordUid: string; inspectionId: string };

function text(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

/** Throws unless the caller may act on this inspection. */
export async function authorizeTenant(
  auth: { uid: string } | undefined,
  data: unknown,
): Promise<Caller & { ref: FirebaseFirestore.DocumentReference; inspection: FirebaseFirestore.DocumentData }> {
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const d = (data ?? {}) as Record<string, unknown>;
  const landlordUid = text(d.landlordUid);
  const inspectionId = text(d.inspectionId);
  if (!landlordUid || !inspectionId || landlordUid.includes("/") || inspectionId.includes("/")) {
    throw new HttpsError("invalid-argument", "landlordUid and inspectionId are required.");
  }
  const db = getFirestore();
  const link = await db.doc(`tenantLinks/${auth.uid}/landlords/${landlordUid}`).get();
  if (!link.exists || link.get("status") !== "active") {
    throw new HttpsError("permission-denied", "You are not an active tenant of this landlord.");
  }
  const ref = db.doc(`landlords/${landlordUid}/inspections/${inspectionId}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Inspection not found.");
  const inspection = snap.data()!;
  const tenantIds: unknown = link.get("tenantIds");
  if (!Array.isArray(tenantIds) || !tenantIds.includes(inspection.tenantId)) {
    throw new HttpsError("permission-denied", "This inspection is not for you.");
  }
  return { uid: auth.uid, landlordUid, inspectionId, ref, inspection };
}

function requireAwaitingTenant(inspection: FirebaseFirestore.DocumentData) {
  if (inspection.status !== "awaitingTenant") {
    throw new HttpsError("failed-precondition", "This inspection isn't waiting for the tenant.");
  }
}

/** Push to the landlord's devices; failures are logged, never thrown. */
async function notifyLandlord(landlordUid: string, title: string, body: string, inspectionId: string) {
  try {
    const db = getFirestore();
    const [user, landlord] = await Promise.all([db.doc(`users/${landlordUid}`).get(), db.doc(`landlords/${landlordUid}`).get()]);
    const tokens = [
      ...new Set<string>([...((user.get("fcmTokens") as string[] | undefined) ?? []), ...((landlord.get("fcmTokens") as string[] | undefined) ?? [])]),
    ];
    if (!tokens.length) return;
    await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { type: "inspection", inspectionId },
    });
  } catch (e) {
    logger.warn("Inspection notification failed", { landlordUid, inspectionId, error: String(e) });
  }
}

/**
 * Firebase-style download URL (same as the app's getDownloadURL()): reuses
 * the token the client SDK stored with the upload, or adds one. Done here
 * rather than with firebase-admin's getDownloadURL so it also works on the
 * Storage emulator.
 */
async function downloadUrl(file: ReturnType<ReturnType<ReturnType<typeof getStorage>["bucket"]>["file"]>): Promise<string> {
  const [meta] = await file.getMetadata();
  let token = String((meta.metadata as Record<string, unknown> | undefined)?.firebaseStorageDownloadTokens ?? "").split(",")[0];
  if (!token) {
    token = randomUUID();
    await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  }
  const emulator = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
  const host = emulator ? `http://${emulator.replace(/^https?:\/\//, "")}` : "https://firebasestorage.googleapis.com";
  return `${host}/v0/b/${file.bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${token}`;
}

const itemExists = (inspection: FirebaseFirestore.DocumentData, itemId: string) =>
  ((inspection.rooms as Array<{ items?: Array<{ id?: string }> }> | undefined) ?? []).some((r) =>
    (r.items ?? []).some((i) => i.id === itemId),
  );

export const addInspectionTenantComment = onCall(async (req) => {
  const c = await authorizeTenant(req.auth, req.data);
  requireAwaitingTenant(c.inspection);
  const body = text(req.data?.text);
  if (!body) throw new HttpsError("invalid-argument", "text is required.");
  if (body.length > MAX_COMMENT) throw new HttpsError("invalid-argument", `Keep comments under ${MAX_COMMENT} characters.`);
  const itemId = text(req.data?.itemId);
  if (itemId && !itemExists(c.inspection, itemId)) throw new HttpsError("invalid-argument", "Unknown item.");
  await c.ref.update({
    tenantComments: FieldValue.arrayUnion({ text: body, at: new Date().toISOString(), ...(itemId ? { itemId } : {}) }),
  });
  await notifyLandlord(c.landlordUid, "New comment on an inspection", body.slice(0, 120), c.inspectionId);
  return { ok: true };
});

export const confirmInspectionAsTenant = onCall(async (req) => {
  const c = await authorizeTenant(req.auth, req.data);
  requireAwaitingTenant(c.inspection);
  const now = new Date().toISOString();
  await c.ref.update({ tenantConfirmedAt: now, completedAt: now, status: "completed" });
  await notifyLandlord(c.landlordUid, "Inspection confirmed", "Your tenant confirmed the inspection.", c.inspectionId);
  return { ok: true };
});

export const attachInspectionTenantMedia = onCall(async (req) => {
  const c = await authorizeTenant(req.auth, req.data);
  requireAwaitingTenant(c.inspection);
  const storagePath = text(req.data?.storagePath);
  const prefix = `tenantUploads/${c.uid}/inspections/${c.inspectionId}/`;
  if (!storagePath.startsWith(prefix) || storagePath.includes("..")) {
    throw new HttpsError("invalid-argument", "Upload the file to your own inspection folder first.");
  }
  const type = text(req.data?.type) === "video" ? "video" : "photo";
  const itemId = text(req.data?.itemId);
  if (itemId && !itemExists(c.inspection, itemId)) throw new HttpsError("invalid-argument", "Unknown item.");
  const file = getStorage().bucket().file(storagePath);
  const [exists] = await file.exists();
  if (!exists) throw new HttpsError("not-found", "Uploaded file not found.");
  const url = await downloadUrl(file);
  await c.ref.update({
    tenantMedia: FieldValue.arrayUnion({
      url,
      storagePath,
      type,
      takenAt: new Date().toISOString(),
      by: "tenant",
      ...(itemId ? { itemId } : {}),
    }),
  });
  await notifyLandlord(c.landlordUid, "New photo on an inspection", "Your tenant added a photo or video.", c.inspectionId);
  return { ok: true, url };
});
