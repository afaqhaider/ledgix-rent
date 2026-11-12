import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { flagOn, UtilityProvider, utilities } from "./integrations/services";

/**
 * Runs daily at 09:00 GST. For each landlord whose configured check day
 * (`utilityCheckDay`, default 1 = monthly on the 1st) is today, fetches the
 * latest bill for every property account and saves new ones, then pushes a
 * notification. Also reminds about unpaid bills due in 3 days.
 */
export const utilityBillCheck = onSchedule({ schedule: "0 9 * * *", timeZone: "Asia/Dubai" }, async () => {
  if (!flagOn("FF_UTILITY_BILLS")) return;
  const db = getFirestore();
  const now = new Date(Date.now() + 4 * 3600 * 1000);
  const today = now.toISOString().slice(0, 10);
  const in3 = new Date(now.getTime() + 3 * 86400000).toISOString().slice(0, 10);

  for (const l of (await db.collection("landlords").get()).docs) {
    const tokens: string[] = l.get("fcmTokens") ?? [];
    const notify = async (title: string, body: string) => {
      if (tokens.length) await getMessaging().sendEachForMulticast({ tokens, notification: { title, body } });
    };

    if ((l.get("utilityCheckDay") ?? 1) === now.getUTCDate()) {
      const bills = await l.ref.collection("utilityBills").get();
      for (const p of (await l.ref.collection("properties").get()).docs) {
        const accounts: [UtilityProvider, string][] = [];
        if (p.get("dewaAccountNo")) accounts.push(["dewa", p.get("dewaAccountNo")]);
        if (p.get("chillerAccountNo")) accounts.push(["chiller", p.get("chillerAccountNo")]);
        for (const [provider, accountNo] of accounts) {
          const info = await utilities().fetchBill(provider, accountNo);
          const period = info.periodEnd.slice(0, 7);
          const exists = bills.docs.some((b) => b.get("propertyId") === p.id && b.get("provider") === provider && b.get("period") === period);
          if (exists) continue;
          const ref = l.ref.collection("utilityBills").doc();
          await ref.set({
            id: ref.id, propertyId: p.id, provider, accountNo, period,
            amount: info.amount, dueDate: info.dueDate, status: "unpaid",
            paidBy: p.get("utilityPaidBy") ?? "tenant", pdfUrl: null, source: "api",
          });
          await notify("New utility bill", `${provider.toUpperCase()} ${p.get("name")}: AED ${info.amount} due ${info.dueDate}`);
        }
      }
    }

    for (const b of (await l.ref.collection("utilityBills").where("status", "==", "unpaid").get()).docs) {
      if (String(b.get("dueDate")).slice(0, 10) === in3) {
        await notify("Utility bill due soon", `A ${String(b.get("provider")).toUpperCase()} bill of AED ${b.get("amount")} is due in 3 days.`);
      }
    }
    void today;
  }
});
