// End-to-end check of the tenant backend on the local emulators (no cloud):
//   cd functions && npm run build && cd .. &&
//   firebase emulators:exec --only firestore,functions,auth,storage --project demo-ledgix-rent \
//     "node functions/scripts/tenant_flow_emulator_test.mjs"
// Invite -> redeem -> read model -> security rules -> removal of a former landlord.
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

async function idToken(uid) {
  const custom = await auth.createCustomToken(uid);
  const r = await fetch(`${AUTH}/accounts:signInWithCustomToken?key=fake`, {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ token: custom, returnSecureToken: true }),
  });
  return (await r.json()).idToken;
}
async function call(name, uid, data) {
  const r = await fetch(`${FN}/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${await idToken(uid)}` },
    body: JSON.stringify({ data }),
  });
  const body = await r.json();
  if (body.error) { const e = new Error(body.error.message); e.reason = body.error.details?.reason; throw e; }
  return body.result;
}
async function readAs(uid, path) {
  const r = await fetch(`${FS}/${path}`, { headers: { Authorization: `Bearer ${await idToken(uid)}` } });
  return r.status;
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const iso = (d) => d.toISOString();

const L1 = "landlord1", L2 = "landlord2", T = "tenantUser";
for (const uid of [L1, L2, T]) await auth.createUser({ uid, email: `${uid}@example.test` }).catch(() => {});

async function seed(ll, ended) {
  const base = db.collection("landlords").doc(ll);
  await base.collection("profile").doc(ll).set({ id: ll, name: `Owner ${ll}`, phone: "0500000000", emiratesIdNo: "784-1970-1111111-1", email: "" });
  await base.collection("properties").doc(`${ll}-p`).set({ id: `${ll}-p`, name: `Tower ${ll}`, dewaPremiseNo: "123456789",
    documents: [{ name: "Deed", url: "https://example.test/deed.pdf", kind: "titleDeed", shared: true },
                { name: "Private", url: "https://example.test/private.pdf", kind: "other", shared: false }] });
  await base.collection("tenants").doc(`${ll}-t`).set({ id: `${ll}-t`, name: "Sam Renter", emiratesIdNo: "784-1990-2222222-2", documents: [] });
  await base.collection("leases").doc(`${ll}-l`).set({ id: `${ll}-l`, propertyId: `${ll}-p`, tenantId: `${ll}-t`,
    startDate: ended ? "2024-01-01T00:00:00.000" : "2026-01-01T00:00:00.000",
    endDate: ended ? "2024-12-31T00:00:00.000" : "2027-12-31T00:00:00.000", annualRent: 120000, status: "active", documents: [] });
  await base.collection("payments").doc(`${ll}-pay1`).set({ id: `${ll}-pay1`, leaseId: `${ll}-l`, type: "cheque", amount: 60000,
    dueDate: iso(new Date(Date.now() + 20 * 86400000)), status: "pending", image: "https://example.test/c1.jpg" });
  await base.collection("payments").doc(`${ll}-pay2`).set({ id: `${ll}-pay2`, leaseId: `${ll}-l`, type: "cheque", amount: 60000,
    dueDate: iso(new Date(Date.now() + 200 * 86400000)), status: "pending", image: "https://example.test/c2.jpg", shareImage: false });
}
await seed(L1, false);
await seed(L2, true);

// Invite + redeem.
const inv = await call("createTenantInvite", L1, { tenantId: `${L1}-t` });
assert.match(inv.code, /^[A-HJ-NP-Z2-9]{8}$/);
await assert.rejects(call("redeemTenantInvite", L1, { code: inv.code }), (e) => e.reason === "ownCode");
await assert.rejects(call("redeemTenantInvite", T, { code: "ZZZZ2222" }), (e) => e.reason === "invalid");
await call("redeemTenantInvite", T, { code: inv.code.toLowerCase() });
await assert.rejects(call("redeemTenantInvite", T, { code: inv.code }), (e) => e.reason === "used");
assert.equal((await db.doc(`landlords/${L1}/tenants/${L1}-t`).get()).get("appUid"), T);

// Read model.
const view = db.collection("tenantViews").doc(T);
const ll = (await view.collection("landlords").doc(L1).get()).data();
assert.equal(ll.name, `Owner ${L1}`);
assert.equal(ll.emiratesIdNo, "784-1970-1111111-1");
assert.equal(ll.email, `${L1}@example.test`); // from Auth when the profile has none
const props = (await view.collection("properties").get()).docs.map((d) => d.data());
assert.equal(props.length, 1);
assert.equal(props[0].agreementAmount, 120000);
const pays = Object.fromEntries((await view.collection("payments").get()).docs.map((d) => [d.id, d.data()]));
assert.equal(pays[`${L1}-pay1`].imageUrl, "https://example.test/c1.jpg");
assert.equal(pays[`${L1}-pay2`].imageUrl, null);
const docs = (await view.collection("documents").get()).docs.map((d) => d.data().name);
assert.deepEqual(docs, ["Deed"]);
assert.equal((await db.doc(`tenantLinks/${T}/landlords/${L1}`).get()).get("status"), "active");

// Trigger keeps it in sync: unshare the deed.
await db.doc(`landlords/${L1}/properties/${L1}-p`).update({
  documents: [{ name: "Deed", url: "https://example.test/deed.pdf", kind: "titleDeed", shared: false }] });
await sleep(4000);
assert.equal((await view.collection("documents").get()).size, 0);

// Rules: tenant reads own view and links, never landlord data or invites.
assert.equal(await readAs(T, `tenantViews/${T}/properties`), 200);
assert.equal(await readAs(T, `tenantLinks/${T}/landlords`), 200);
assert.equal(await readAs(T, `landlords/${L1}/properties`), 403);
assert.equal(await readAs(T, `invites/${inv.code}`), 403);
assert.equal(await readAs(L1, `tenantViews/${T}/properties`), 403);

// Second landlord with an ended lease -> former; can be removed; active one can't.
const inv2 = await call("createTenantInvite", L2, { tenantId: `${L2}-t` });
await call("redeemTenantInvite", T, { code: inv2.code });
assert.equal((await db.doc(`tenantLinks/${T}/landlords/${L2}`).get()).get("status"), "former");
await assert.rejects(call("removeLandlordLink", T, { landlordUid: L1 }), (e) => e.reason === "active");
await call("removeLandlordLink", T, { landlordUid: L2 });
assert.equal((await db.doc(`tenantLinks/${T}/landlords/${L2}`).get()).exists, false);
assert.equal((await view.collection("landlords").doc(L2).get()).exists, false);
assert.equal((await db.doc(`landlords/${L2}/tenants/${L2}-t`).get()).get("appUid"), undefined);

// Maintenance request lands in the landlord's tickets.
const req = await call("createTenantMaintenanceRequest", T, { landlordUid: L1, propertyId: `${L1}-p`, title: "AC not cooling" });
const ticket = (await db.doc(`landlords/${L1}/maintenanceTickets/${req.id}`).get()).data();
assert.equal(ticket.raisedBy, "tenant");

// Tenant deletes their account: links and views go, landlord record is unlinked.
await call("deleteAccount", T, {});
assert.equal((await db.collection(`tenantViews/${T}/properties`).get()).size, 0);
assert.equal((await db.doc(`landlords/${L1}/tenants/${L1}-t`).get()).get("appUid"), undefined);

console.log("TENANT FLOW EMULATOR TEST PASSED");
process.exit(0);
