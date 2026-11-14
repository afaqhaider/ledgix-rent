import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { landlordTokens, notify, userTokens } from "./tenants";

initializeApp();

const DEPOSIT_DAYS = [3, 1];
const RENEWAL_DAYS = [90, 60, 30];
const TENANT_RENT_DAYS = [7, 3, 1, 0];
const TENANT_LEASE_END_DAYS = [60, 30];

/** Today in Gulf Standard Time (UTC+4) as yyyy-MM-dd. */
function todayGst(): string {
  return new Date(Date.now() + 4 * 3600 * 1000).toISOString().slice(0, 10);
}

function addDays(isoDate: string, days: number): string {
  const d = new Date(isoDate + "T00:00:00Z");
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/**
 * Runs every day at 08:00 GST. For every landlord it sends push reminders:
 *  - 3 and 1 days before each pending / on-hold payment's due date
 *  - 90, 60 and 30 days before an active lease ends
 * Mirrors lib/features/payments/domain/reminder_planner.dart.
 */
export const dailyReminders = onSchedule(
  { schedule: "0 8 * * *", timeZone: "Asia/Dubai" },
  async () => {
    const db = getFirestore();
    const today = todayGst();
    const landlords = await db.collection("landlords").get();

    for (const l of landlords.docs) {
      const messages: { title: string; body: string }[] = [];
      const payments = await l.ref.collection("payments").get();
      const leases = await l.ref.collection("leases").get();

      for (const p of payments.docs) {
        const status = p.get("status");
        if (status !== "pending" && status !== "onHold") continue;
        const due = String(p.get("dueDate")).slice(0, 10);
        for (const d of DEPOSIT_DAYS) {
          if (addDays(due, -d) === today) {
            messages.push({
              title: "Cheque deposit reminder",
              body: `AED ${p.get("amount")} is due in ${d} day(s) (${due}).`,
            });
          }
        }
      }
      for (const le of leases.docs) {
        if (le.get("status") !== "active") continue;
        const end = String(le.get("ejariExpiry") ?? le.get("endDate")).slice(0, 10); // Ejari expiry when known
        for (const d of RENEWAL_DAYS) {
          if (addDays(end, -d) === today) {
            messages.push({ title: "Lease renewal", body: `A lease ends in ${d} days (${end}).` });
          }
        }
      }
      const tokens = await landlordTokens(l.id);
      for (const m of messages) await notify(tokens, m);

      // Tenants who joined the app: rent reminders and lease-end reminders.
      const tenants = await l.ref.collection("tenants").where("appUid", "!=", null).get();
      for (const t of tenants.docs) {
        const uid = t.get("appUid") as string;
        const mine = leases.docs.filter((x) => x.get("tenantId") === t.id);
        const leaseIds = new Set(mine.map((x) => x.id));
        const tenantMessages: { title: string; body: string }[] = [];
        for (const p of payments.docs) {
          if (!leaseIds.has(p.get("leaseId"))) continue;
          const status = p.get("status");
          if (status !== "pending" && status !== "onHold") continue;
          const due = String(p.get("dueDate")).slice(0, 10);
          for (const d of TENANT_RENT_DAYS) {
            if (addDays(due, -d) === today) {
              tenantMessages.push({
                title: "Rent payment reminder",
                body: d === 0
                  ? `Your rent payment of AED ${p.get("amount")} is due today.`
                  : `Your rent payment of AED ${p.get("amount")} is due in ${d} day(s) (${due}).`,
              });
            }
          }
        }
        for (const le of mine) {
          if (le.get("status") !== "active") continue;
          const end = String(le.get("endDate")).slice(0, 10);
          for (const d of TENANT_LEASE_END_DAYS) {
            if (addDays(end, -d) === today) {
              tenantMessages.push({ title: "Lease ending soon", body: `Your lease ends in ${d} days (${end}).` });
            }
          }
        }
        if (tenantMessages.length === 0) continue;
        const tenantTokens = await userTokens(uid);
        for (const m of tenantMessages) await notify(tenantTokens, m);
      }
    }
  }
);

// Add-ons
export { ejariLookup, mollakQuery, utilityFetch } from "./integrations/callables";
export { deliverWorkOrder, quotePage } from "./maintenance";
export { utilityBillCheck } from "./utilityBills";

// Account
export { deleteAccount } from "./account";

// Tenants: invites, links, read model, maintenance requests
export {
  createTenantInvite, redeemTenantInvite, removeLandlordLink,
  createTenantMaintenanceRequest, onLandlordDataWritten,
} from "./tenants";

// LedGix ID (Hub) sign-in
export { exchangeLedgixHubSession } from "./hub";

// Move-in / move-out inspections: tenant actions
export { addInspectionTenantComment, attachInspectionTenantMedia, confirmInspectionAsTenant } from "./inspections";
