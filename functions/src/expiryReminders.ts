import type { DocumentData, DocumentReference } from "firebase-admin/firestore";
import { notify, userTokens } from "./tenants";

/** Days before an Emirates ID / passport expiry when the landlord is reminded (0 = on the day). */
export const LANDLORD_ID_DAYS = [60, 30, 7, 0];
/** Days before a tenant's own Emirates ID / passport expiry when the tenant is reminded. */
export const TENANT_ID_DAYS = [30, 7, 0];

type Message = { title: string; body: string };

/** Whole days from today to [date] (both yyyy-MM-dd). */
function daysBetween(today: string, date: string): number {
  return Math.round((Date.parse(date + "T00:00:00Z") - Date.parse(today + "T00:00:00Z")) / 86400000);
}

function day(v: unknown): string | null {
  const s = typeof v === "string" ? v.slice(0, 10) : "";
  return /^\d{4}-\d{2}-\d{2}$/.test(s) ? s : null;
}

function when(days: number, date: string): string {
  return days === 0 ? "today" : `in ${days} days (${date})`;
}

function tenantName(t: DocumentData): string {
  const parts = [t.firstName, t.middleName, t.lastName].filter((s) => typeof s === "string" && s.trim());
  return parts.length ? parts.join(" ") : String(t.name ?? "A tenant");
}

/**
 * Reminders about Emirates ID and passport expiry dates for one landlord:
 * their tenants', their property owners' and their own. Pure, for testing.
 */
export function idExpiryMessages(
  today: string,
  input: { tenants: DocumentData[]; properties: DocumentData[]; profile: DocumentData | null },
): { landlord: Message[]; tenants: Map<string, Message[]> } {
  const landlord: Message[] = [];
  const tenants = new Map<string, Message[]>();
  const check = (date: unknown, days: number[], make: (d: number, on: string) => Message, out: Message[]) => {
    const on = day(date);
    if (!on) return;
    const d = daysBetween(today, on);
    if (days.includes(d)) out.push(make(d, on));
  };
  const docs = [
    { key: "emiratesIdExpiry", label: "Emirates ID" },
    { key: "passportExpiry", label: "passport" },
  ];

  for (const t of input.tenants) {
    const name = tenantName(t);
    for (const doc of docs) {
      check(t[doc.key], LANDLORD_ID_DAYS, (d, on) => ({
        title: "Tenant ID expiry",
        body: `${name}'s ${doc.label} expires ${when(d, on)}.`,
      }), landlord);
      // The tenant hears about their own ID only (never anyone else's).
      if (typeof t.appUid === "string" && t.appUid) {
        const mine = tenants.get(t.appUid) ?? [];
        check(t[doc.key], TENANT_ID_DAYS, (d, on) => ({
          title: "Your ID is expiring",
          body: `Your ${doc.label} expires ${when(d, on)}. Please renew it and share the new copy with your landlord.`,
        }), mine);
        if (mine.length) tenants.set(t.appUid, mine);
      }
    }
  }
  for (const p of input.properties) {
    const name = String(p.name ?? "a property");
    for (const doc of [
      { key: "ownerEmiratesIdExpiry", label: "Emirates ID" },
      { key: "ownerPassportExpiry", label: "passport" },
    ]) {
      check(p[doc.key], LANDLORD_ID_DAYS, (d, on) => ({
        title: "Owner ID expiry",
        body: `The owner's ${doc.label} for ${name} expires ${when(d, on)}.`,
      }), landlord);
    }
  }
  if (input.profile) {
    for (const doc of docs) {
      check(input.profile[doc.key], LANDLORD_ID_DAYS, (d, on) => ({
        title: "Your ID is expiring",
        body: `Your ${doc.label} expires ${when(d, on)}.`,
      }), landlord);
    }
  }
  return { landlord, tenants };
}

/** Sends today's ID expiry reminders for the landlord at [ref]. */
export async function sendIdExpiryReminders(ref: DocumentReference, today: string, landlordTokens: string[]): Promise<void> {
  const [tenants, properties, profile] = await Promise.all([
    ref.collection("tenants").get(),
    ref.collection("properties").get(),
    ref.collection("profile").limit(1).get(),
  ]);
  const m = idExpiryMessages(today, {
    tenants: tenants.docs.map((d) => d.data()),
    properties: properties.docs.map((d) => d.data()),
    profile: profile.docs[0]?.data() ?? null,
  });
  for (const msg of m.landlord) await notify(landlordTokens, msg);
  for (const [uid, msgs] of m.tenants) {
    const tokens = await userTokens(uid);
    for (const msg of msgs) await notify(tokens, msg);
  }
}
