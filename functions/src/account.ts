import { HttpsError, onCall } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { LINKS } from "./hub";

/**
 * Permanently deletes the caller's account: every Firestore document under
 * landlords/{uid} (all sub-collections), every Storage file under
 * landlords/{uid}/, its LedGix ID links, then the Auth user. The person's
 * LedGix ID itself is not touched. Required by App Store guideline
 * 5.1.1(v) and Google Play's account deletion policy.
 */
export const deleteAccount = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

  const db = getFirestore();
  await db.recursiveDelete(db.doc(`landlords/${uid}`));
  await getStorage().bucket().deleteFiles({ prefix: `landlords/${uid}/` });
  const links = await db.collection(LINKS).where("localUid", "==", uid).get();
  await Promise.all(links.docs.map((d) => d.ref.delete()));
  await getAuth().deleteUser(uid);
  return { deleted: true };
});
