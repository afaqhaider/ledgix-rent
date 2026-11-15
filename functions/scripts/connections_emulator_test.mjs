// End-to-end check of connection requests on the local emulators (no cloud):
//   cd functions && npm run build && cd .. &&
//   firebase emulators:exec --only firestore,functions,auth --project demo-ledgix-rent \
//     "node functions/scripts/connections_emulator_test.mjs"
// Lookup by email/code -> share codes -> invitations both ways -> consent ->
// rules on connectionRequests and users.shareCode -> rate limit.
import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(new URL("../package.json", import.meta.url));
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

const PROJECT = process.env.GCLOUD_PROJECT || "demo-ledgix-rent";
initializeApp({ projectId: PROJECT });
const db = getFirestore();
const auth = getAuth();
const FS = `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;
const FN = `http://127.0.0.1:5001/${PROJECT}/us-central1`;
const AUTH = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1`;

const tokens = new Map();
async function idToken(uid) {
  if (tokens.has(uid)) return tokens.get(uid);
  const custom = await auth.createCustomToken(uid);
  const r = await fetch(`${AUTH}/accounts:signInWithCustomToken?key=fake`, {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ token: custom, returnSecureToken: true }),
  });
  const t = (await r.json()).idToken;
  tokens.set(uid, t);
  return t;
}
async function call(name, uid, data) {
  const r = await fetch(`${FN}/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${await idToken(uid)}` },
    body: JSON.stringify({ data }),
  });
  const body = await r.json();
  if (body.error) { const e = new Error(body.error.message); e.reason = body.error.details?.reason; e.status = body.error.status; throw e; }
  return body.result;
}
async function refused(p, reason) {
  try { await p; } catch (e) { if (reason) assert.equal(e.reason, reason, e.message); return; }
  assert.fail(`expected refusal${reason ? ` (${reason})` : ""}`);
}
async function readAs(uid, path) {
  const r = await fetch(`${FS}/${path}`, { headers: { Authorization: `Bearer ${await idToken(uid)}` } });
  return r.status;
}
async function patchAs(uid, path, fields) {
  const mask = Object.keys(fields).map((k) => `updateMask.fieldPaths=${k}`).join("&");
  const body = { fields: Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, { stringValue: v }])) };
  const r = await fetch(`${FS}/${path}?${mask}`, {
    method: "PATCH", headers: { "Content-Type": "application/json", Authorization: `Bearer ${await idToken(uid)}` },
    body: JSON.stringify(body),
  });
  return r.status;
}
let passed = 0;
async function check(name, fn) { await fn(); passed++; console.log(`ok  ${name}`); }

const L1 = "cxLandlord1", L2 = "cxLandlord2", T = "cxTenant", T2 = "cxTenant2", S = "cxStranger";
for (const uid of [L1, L2, T, T2, S]) await auth.createUser({ uid, email: `${uid.toLowerCase()}@example.test` }).catch(() => {});
await db.doc(`users/${L1}`).set({ id: L1, role: "landlord", name: "Owner One", email: "cxlandlord1@example.test" });
await db.doc(`users/${L2}`).set({ id: L2, role: "landlord", name: "Owner Two", email: "cxlandlord2@example.test" });
await db.doc(`users/${T}`).set({ id: T, role: "tenant", name: "Sam Middle Renter", email: "cxtenant@example.test",
  phone: "0509999999", passportNo: "P1234567", passportExpiry: "2030-05-01" });
await db.doc(`users/${T2}`).set({ id: T2, role: "tenant", name: "Other Tenant", email: "cxtenant2@example.test" });
for (const ll of [L1, L2]) {
  const base = db.collection("landlords").doc(ll);
  await base.collection("profile").doc(ll).set({ id: ll, name: ll === L1 ? "Owner One" : "Owner Two" });
  await base.collection("properties").doc(`${ll}-p`).set({ id: `${ll}-p`, name: `Tower ${ll}`, documents: [] });
  await base.collection("tenants").doc(`${ll}-t`).set({ id: `${ll}-t`, name: "Sam Renter", firstName: "Sam", lastName: "Renter",
    phone: "0501111111", email: "", emiratesIdNo: "784-1990-2222222-2", passportNo: "", documents: [] });
  await base.collection("leases").doc(`${ll}-l`).set({ id: `${ll}-l`, propertyId: `${ll}-p`, tenantId: `${ll}-t`,
    startDate: "2026-01-01T00:00:00.000", endDate: "2027-12-31T00:00:00.000", annualRent: 90000, status: "active", documents: [] });
}

await check("lookup by email: none / self / exists with role", async () => {
  assert.deepEqual(await call("lookupAccount", L1, { email: "nobody@example.test" }), { exists: false });
  assert.equal((await call("lookupAccount", L1, { email: "cxlandlord1@example.test" })).self, true);
  const r = await call("lookupAccount", L1, { email: "CXTENANT@example.test" });
  assert.deepEqual(r, { exists: true, linked: false, role: "tenant" });
  assert.equal(Object.keys(r).includes("name"), false); // never reveals details
});

let codeL2;
await check("share codes: created once, stable, found by lookup, not client-writable", async () => {
  codeL2 = (await call("getMyShareCode", L2, {})).code;
  assert.match(codeL2, /^LGX-[A-Z2-9]{6}$/);
  assert.equal((await call("getMyShareCode", L2, {})).code, codeL2);
  assert.equal((await call("lookupAccount", T, { code: codeL2.toLowerCase().replace("-", " ") })).role, "landlord");
  assert.equal(await patchAs(L2, `users/${L2}`, { shareCode: "LGX-AAAAAA" }), 403);
  assert.equal(await patchAs(T, `users/${T}`, { phone: "0508888888" }), 200);
  assert.equal(await readAs(T, `shareCodes/${codeL2}`), 403);
});

let invId;
await check("landlord invites by email; duplicate refused; only sender and recipient can read", async () => {
  invId = (await call("sendConnectionRequest", L1, { direction: "landlordToTenant", tenantRecordId: `${L1}-t`, email: "cxtenant@example.test" })).id;
  await refused(call("sendConnectionRequest", L1, { direction: "landlordToTenant", tenantRecordId: `${L1}-t`, email: "cxtenant@example.test" }), "duplicate");
  await refused(call("sendConnectionRequest", L1, { direction: "landlordToTenant", tenantRecordId: `${L1}-t`, email: "nobody@example.test" }), "notFound");
  await refused(call("sendConnectionRequest", L1, { direction: "landlordToTenant", tenantRecordId: `${L1}-t`, email: "cxlandlord1@example.test" }), "self");
  const r = (await db.doc(`connectionRequests/${invId}`).get()).data();
  assert.equal(r.propertyName, `Tower ${L1}`);
  assert.equal(r.fromName, "Owner One");
  assert.equal(await readAs(T, `connectionRequests/${invId}`), 200);
  assert.equal(await readAs(L1, `connectionRequests/${invId}`), 200);
  assert.equal(await readAs(S, `connectionRequests/${invId}`), 403);
});

await check("only the recipient accepts; accept with consent links and fills empty fields only", async () => {
  await refused(call("respondToConnectionRequest", L1, { requestId: invId, action: "accept" }), "notAllowed");
  await refused(call("respondToConnectionRequest", T, { requestId: invId, action: "cancel" }), "notAllowed");
  await call("respondToConnectionRequest", T, { requestId: invId, action: "accept", shareDetails: true });
  const rec = (await db.doc(`landlords/${L1}/tenants/${L1}-t`).get()).data();
  assert.equal(rec.appUid, T);
  assert.equal(rec.phone, "0501111111"); // landlord's value kept
  assert.equal(rec.passportNo, "P1234567"); // filled
  assert.equal(rec.passportExpiry, "2030-05-01");
  assert.equal((await db.doc(`tenantLinks/${T}/landlords/${L1}`).get()).get("status"), "active");
  assert.equal((await db.doc(`tenantViews/${T}/properties/${L1}-p`).get()).exists, true);
  assert.equal((await db.doc(`connectionRequests/${invId}`).get()).get("status"), "accepted");
  assert.equal((await call("lookupAccount", L1, { email: "cxtenant@example.test" })).linked, true);
});

await check("tenant asks a landlord by code; landlord declines; another is cancelled by the sender", async () => {
  const id = (await call("sendConnectionRequest", T, { direction: "tenantToLandlord", code: codeL2, shareDetails: true })).id;
  const r = (await db.doc(`connectionRequests/${id}`).get()).data();
  assert.equal(r.target, codeL2);
  assert.equal(r.details.passportNo, "P1234567");
  await refused(call("sendConnectionRequest", T, { direction: "tenantToLandlord", code: codeL2 }), "duplicate");
  await call("respondToConnectionRequest", L2, { requestId: id, action: "decline" });
  assert.equal((await db.doc(`connectionRequests/${id}`).get()).get("status"), "declined");
  assert.equal((await db.doc(`landlords/${L2}/tenants/${L2}-t`).get()).get("appUid"), undefined);

  const id2 = (await call("sendConnectionRequest", T, { direction: "tenantToLandlord", email: "cxlandlord2@example.test" })).id;
  await call("respondToConnectionRequest", T, { requestId: id2, action: "cancel" });
  assert.equal((await db.doc(`connectionRequests/${id2}`).get()).get("status"), "cancelled");
});

await check("landlord accepts a tenant's request by picking the record", async () => {
  const id = (await call("sendConnectionRequest", T, { direction: "tenantToLandlord", email: "cxlandlord2@example.test", shareDetails: false })).id;
  await refused(call("respondToConnectionRequest", L2, { requestId: id, action: "accept" }), "invalid"); // must pick a record
  await call("respondToConnectionRequest", L2, { requestId: id, action: "accept", tenantRecordId: `${L2}-t` });
  const rec = (await db.doc(`landlords/${L2}/tenants/${L2}-t`).get()).data();
  assert.equal(rec.appUid, T);
  assert.equal(rec.passportNo, ""); // nothing shared without consent
});

await check("a tenant account can't be asked to be a landlord", async () => {
  await refused(call("sendConnectionRequest", T, { direction: "tenantToLandlord", email: "cxtenant2@example.test" }), "wrongRole");
});

await check("lookups are rate limited", async () => {
  let refusedAt = 0;
  for (let i = 1; i <= 31; i++) {
    try { await call("lookupAccount", S, { email: "x@example.test" }); } catch (e) { refusedAt = i; assert.equal(e.reason, "rateLimited"); break; }
  }
  assert.equal(refusedAt, 31);
});

console.log(`\n${passed} checks passed`);
process.exit(0);
