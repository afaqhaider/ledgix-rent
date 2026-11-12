import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

const DEPOSIT_DAYS = [3, 1];
const RENEWAL_DAYS = [90, 60, 30];

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
      const tokens: string[] = l.get("fcmTokens") ?? [];
      if (tokens.length === 0) continue;
      const messages: { title: string; body: string }[] = [];

      const payments = await l.ref.collection("payments").get();
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

      const leases = await l.ref.collection("leases").get();
      for (const le of leases.docs) {
        if (le.get("status") !== "active") continue;
        const end = String(le.get("endDate")).slice(0, 10);
        for (const d of RENEWAL_DAYS) {
          if (addDays(end, -d) === today) {
            messages.push({
              title: "Lease renewal",
              body: `A lease ends in ${d} days (${end}).`,
            });
          }
        }
      }

      for (const m of messages) {
        await getMessaging().sendEachForMulticast({ tokens, notification: m });
      }
    }
  }
);
