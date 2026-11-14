import { HttpsError, onCall } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { LINKS } from "./hub";
import { unlinkTenant } from "./tenants";

/**
 * Permanently deletes the caller's account, landlord or tenant: every
 * Firestore document under landlords/{uid}, users/{uid}, tenantViews/{uid}
 * and tenantLinks/{uid}, every Storage file under landlords/{uid}/ and
 * tenants/{uid}/, the landlord <-> tenant links on both sides, its LedGix ID
 * links, then the Auth user. The person's
 * LedGix ID itself is not touched. Required by App Store guideline
 * 5.1.1(v) and Google Play's account deletion policy.
 */
export const deleteAccount = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

  const db = getFirestore();

  // As a landlord: disconnect every tenant who joined through this account.
  const joined = await db.collection(`landlords/${uid}/tenants`).where("appUid", "!=", null).get();
  for (const t of joined.docs) await unlinkTenant(uid, t.get("appUid") as string);

  // As a tenant: disconnect from every landlord, then drop the read model.
  const links = await db.collection(`tenantLinks/${uid}/landlords`).get();
  for (const l of links.docs) await unlinkTenant(l.id, uid);
  await db.recursiveDelete(db.doc(`tenantViews/${uid}`));
  await db.recursiveDelete(db.doc(`tenantLinks/${uid}`));
  const invites = await db.collection("invites").where("landlordUid", "==", uid).get();
  await Promise.all(invites.docs.map((d) => d.ref.delete()));

  await db.recursiveDelete(db.doc(`landlords/${uid}`));
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await db.doc(`inviteQuota/${uid}`).delete();
  await getStorage().bucket().deleteFiles({ prefix: `landlords/${uid}/` });
  await getStorage().bucket().deleteFiles({ prefix: `tenants/${uid}/` });
  // Photos and videos this person added to inspections as a tenant.
  await getStorage().bucket().deleteFiles({ prefix: `tenantUploads/${uid}/` });
  const hubLinks = await db.collection(LINKS).where("localUid", "==", uid).get();
  await Promise.all(hubLinks.docs.map((d) => d.ref.delete()));
  await getAuth().deleteUser(uid);
  return { deleted: true };
});
