import type { DocumentData, DocumentReference } from "firebase-admin/firestore";
import { notify } from "./tenants";

/** Days before a service-charge instalment is due when the landlord is reminded. */
export const SERVICE_CHARGE_DAYS = [14, 7, 1];
/** Days after the due date when an unpaid instalment is flagged as overdue. */
export const SERVICE_CHARGE_OVERDUE_DAYS = [1, 7, 30];

type Message = { title: string; body: string };

function daysBetween(today: string, date: string): number {
  return Math.round((Date.parse(date + "T00:00:00Z") - Date.parse(today + "T00:00:00Z")) / 86400000);
}

function day(v: unknown): string | null {
  const s = typeof v === "string" ? v.slice(0, 10) : "";
  return /^\d{4}-\d{2}-\d{2}$/.test(s) ? s : null;
}

/**
 * Service-charge reminders for one landlord: 14, 7 and 1 days before each
 * unpaid instalment is due, and 1, 7 and 30 days after if still unpaid.
 * Pure, for testing. Expenses are landlord-only and never reach tenants.
 */
export function serviceChargeMessages(today: string, expenses: DocumentData[], propertyNames: Map<string, string>): Message[] {
  const out: Message[] = [];
  for (const e of expenses) {
    if (e.type !== "serviceCharge" || e.status === "paid") continue;
    const due = day(e.dueDate);
    if (!due) continue;
    const d = daysBetween(today, due);
    const what = `${propertyNames.get(String(e.propertyId)) ?? "A property"}${e.period ? ` (${e.period})` : ""}`;
    const amount = `AED ${Number(e.amount ?? 0).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    if (SERVICE_CHARGE_DAYS.includes(d)) {
      out.push({ title: "Service charge due soon", body: `${what}: ${amount} is due in ${d} day${d === 1 ? "" : "s"} (${due}).` });
    } else if (SERVICE_CHARGE_OVERDUE_DAYS.includes(-d)) {
      out.push({ title: "Service charge overdue", body: `${what}: ${amount} was due on ${due} and isn't marked paid.` });
    }
  }
  return out;
}

/** Sends one landlord's service-charge reminders. */
export async function sendServiceChargeReminders(landlord: DocumentReference, today: string, tokens: string[]): Promise<void> {
  if (tokens.length === 0) return;
  const [expenses, properties] = await Promise.all([
    landlord.collection("expenses").where("type", "==", "serviceCharge").get(),
    landlord.collection("properties").get(),
  ]);
  const names = new Map(properties.docs.map((p) => [p.id, String(p.get("name") ?? "")]));
  for (const m of serviceChargeMessages(today, expenses.docs.map((d) => d.data()), names)) await notify(tokens, m);
}
