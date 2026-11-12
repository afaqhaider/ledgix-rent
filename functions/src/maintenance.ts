import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { email, flagOn } from "./integrations/services";

/** Public base URL of the quote page, set by the owner after deploy, e.g. https://<region>-<project>.cloudfunctions.net/quotePage */
const quotePageUrl = () => process.env.QUOTE_PAGE_URL ?? "https://example.invalid/quotePage";

/**
 * A landlord forwarded a request: deliver the work order.
 *  - channel "app": push notification to the company's LedGix Rent account
 *  - channel "email": email with a secure, expiring link to the quote page
 */
export const deliverWorkOrder = onDocumentCreated("landlords/{uid}/workOrders/{id}", async (event) => {
  if (!flagOn("FF_FORWARDING")) return;
  const o = event.data?.data();
  if (!o) return;

  if (o.channel === "app" && o.vendorAccountId) {
    const vendor = await getFirestore().collection("landlords").doc(String(o.vendorAccountId)).get();
    const tokens: string[] = vendor.get("fcmTokens") ?? [];
    if (tokens.length) {
      await getMessaging().sendEachForMulticast({
        tokens,
        notification: { title: "New work order", body: String(o.body).split("\n")[0] },
      });
    }
  } else if (o.vendorEmail) {
    const link = `${quotePageUrl()}?u=${event.params.uid}&o=${event.params.id}&t=${o.token}`;
    await email().send({
      to: String(o.vendorEmail),
      subject: String(o.body).split("\n")[0],
      text: `${o.body}\n\nView the job and submit your quote (no sign-up needed, link expires ${String(o.expiresAt).slice(0, 10)}):\n${link}`,
      attachmentUrls: o.attachments ?? [],
    });
  }
  await event.data!.ref.update({ sentAt: new Date().toISOString() });
});

const esc = (s: unknown) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));

/**
 * Web page for companies without the app. GET shows the job, POST saves a quote.
 * The link is valid only with the right token and until the work order expires.
 */
export const quotePage = onRequest(async (req, res) => {
  const q = req.method === "POST" ? req.body : req.query;
  const uid = String(q.u ?? ""), id = String(q.o ?? ""), token = String(q.t ?? "");
  if (!uid || !id || !token) { res.status(400).send("Invalid link."); return; }

  const ref = getFirestore().doc(`landlords/${uid}/workOrders/${id}`);
  const snap = await ref.get();
  const o = snap.data();
  if (!o || o.token !== token) { res.status(403).send("Invalid link."); return; }
  if (Date.parse(o.expiresAt) <= Date.now()) { res.status(410).send("This link has expired."); return; }

  if (req.method === "POST") {
    const amount = Number(req.body.amount);
    if (!Number.isFinite(amount) || amount <= 0) { res.status(400).send("Enter a valid amount."); return; }
    const quote = getFirestore().collection(`landlords/${uid}/quotes`).doc();
    await quote.set({
      id: quote.id,
      ticketId: o.ticketId,
      vendorId: o.vendorId,
      amount,
      vat: Number(req.body.vat) || 0,
      scope: String(req.body.scope ?? "").slice(0, 2000),
      proposedVisit: req.body.visit ? new Date(String(req.body.visit)).toISOString() : null,
      status: "submitted",
      question: "",
      invoiceUrl: null,
      completionPhotos: [],
    });
    await getFirestore().doc(`landlords/${uid}/maintenanceTickets/${o.ticketId}`).update({ status: "quoted" });
    res.send("<h3>Thank you, your quote was sent to the landlord.</h3>");
    return;
  }

  res.send(`<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1">
<body style="font-family:sans-serif;max-width:560px;margin:24px auto;padding:0 16px">
<h2>Work order</h2><pre style="white-space:pre-wrap">${esc(o.body)}</pre>
<form method="post">
<input type="hidden" name="u" value="${esc(uid)}"><input type="hidden" name="o" value="${esc(id)}"><input type="hidden" name="t" value="${esc(token)}">
<p><label>Price (AED)<br><input name="amount" type="number" step="0.01" required></label></p>
<p><label>VAT (AED)<br><input name="vat" type="number" step="0.01"></label></p>
<p><label>Scope of work<br><textarea name="scope" rows="4" style="width:100%"></textarea></label></p>
<p><label>Proposed visit<br><input name="visit" type="datetime-local"></label></p>
<button>Submit quote</button></form></body>`);
});
