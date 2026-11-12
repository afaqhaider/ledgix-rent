/**
 * Server-side integration interfaces. Each has a mock implementation that
 * works without credentials; the live gateway is selected per environment
 * with EJARI_MODE / MOLLAK_MODE / UTILITY_MODE / EMAIL_MODE = "live".
 * Credentials are read from environment variables or Secret Manager by the
 * owner (see README); nothing is hard-coded here.
 */

export interface EjariContract {
  ejariNo: string;
  startDate: string; // ISO
  expiry: string; // ISO
  annualRent?: number;
  tenantName?: string;
  unitRef?: string;
}
export interface EjariService {
  lookupContract(ejariNo: string): Promise<EjariContract>;
}

export interface MollakCharge { period: string; amount: number; dueDate: string; paid: boolean }
export interface MollakBudget { year: number; totalBudget: number; spent: number; reserveFund: number }
export interface MollakService {
  getServiceCharges(unitRef: string): Promise<MollakCharge[]>;
  getOutstandingBalance(unitRef: string): Promise<number>;
  getBudget(projectRef: string): Promise<MollakBudget>;
}

export type UtilityProvider = "dewa" | "chiller" | "sewa" | "addc" | "aadc";
export interface UtilityBillInfo {
  amount: number;
  currency: string;
  dueDate: string;
  periodStart: string;
  periodEnd: string;
}
export interface UtilityBillService {
  fetchBill(provider: UtilityProvider, accountNo: string): Promise<UtilityBillInfo>;
  payBill(provider: UtilityProvider, accountNo: string, amount: number): Promise<{ supported: boolean; message: string }>;
}

export interface EmailMessage {
  to: string;
  subject: string;
  text: string;
  attachmentUrls?: string[];
}
/** Pluggable: the owner picks the provider (SendGrid, Postmark, SES...). */
export interface EmailService {
  send(msg: EmailMessage): Promise<void>;
}

// ---------------------------------------------------------------- helpers
const iso = (d: Date) => d.toISOString().slice(0, 10);
const seed = (s: string) => [...s].reduce((a, c) => (a * 31 + c.charCodeAt(0)) & 0x7fffffff, 7);
const gstNow = () => new Date(Date.now() + 4 * 3600 * 1000);

// ------------------------------------------------------------------ mocks
export class MockEjariService implements EjariService {
  async lookupContract(ejariNo: string): Promise<EjariContract> {
    const n = seed(ejariNo);
    const expiry = new Date(gstNow().getTime() + ((n % 11) * 30 - 30) * 86400000);
    const start = new Date(expiry);
    start.setUTCFullYear(start.getUTCFullYear() - 1);
    start.setUTCDate(start.getUTCDate() + 1);
    return {
      ejariNo,
      startDate: iso(start),
      expiry: iso(expiry),
      annualRent: 60000 + (n % 12) * 5000,
      tenantName: "Sample Tenant",
      unitRef: `DXB-${(n % 9000) + 1000}`,
    };
  }
}

export class MockMollakService implements MollakService {
  async getServiceCharges(unitRef: string): Promise<MollakCharge[]> {
    const now = gstNow();
    const base = 4000 + (seed(unitRef) % 20) * 100;
    return [0, 1, 2, 3].map((i) => {
      const due = new Date(Date.UTC(now.getUTCFullYear(), i * 3, 1));
      return {
        period: `Q${i + 1} ${now.getUTCFullYear()}`,
        amount: base,
        dueDate: iso(due),
        paid: due.getTime() < now.getTime() - 30 * 86400000,
      };
    });
  }
  async getOutstandingBalance(unitRef: string): Promise<number> {
    return (await this.getServiceCharges(unitRef)).filter((c) => !c.paid).reduce((a, c) => a + c.amount, 0);
  }
  async getBudget(projectRef: string): Promise<MollakBudget> {
    const total = 2500000 + (seed(projectRef) % 10) * 100000;
    return { year: gstNow().getUTCFullYear(), totalBudget: total, spent: total * 0.42, reserveFund: total * 0.15 };
  }
}

export class MockUtilityBillService implements UtilityBillService {
  async fetchBill(provider: UtilityProvider, accountNo: string): Promise<UtilityBillInfo> {
    const now = gstNow();
    const n = seed(provider + accountNo);
    const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 0));
    return {
      amount: (provider === "chiller" ? 350 : 400) + (n % 60) * 10,
      currency: "AED",
      dueDate: iso(new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 20))),
      periodStart: iso(new Date(Date.UTC(end.getUTCFullYear(), end.getUTCMonth(), 1))),
      periodEnd: iso(end),
    };
  }
  async payBill() {
    return { supported: false, message: "Online bill payment is not available yet." };
  }
}

/** Logs instead of sending. Replace with a real provider by implementing EmailService. */
export class MockEmailService implements EmailService {
  async send(msg: EmailMessage): Promise<void> {
    console.log(`[mock email] to=${msg.to} subject="${msg.subject}"\n${msg.text}`);
  }
}

// ------------------------------------------------- live stubs (not wired)
class NotConfigured extends Error {
  constructor(what: string) {
    super(`${what} live gateway is not configured. Add credentials as described in the README, then implement it here.`);
  }
}
export class LiveEjariService implements EjariService {
  async lookupContract(): Promise<EjariContract> {
    throw new NotConfigured("Ejari (DLD API Gateway)");
  }
}
export class LiveMollakService implements MollakService {
  async getServiceCharges(): Promise<MollakCharge[]> { throw new NotConfigured("Mollak"); }
  async getOutstandingBalance(): Promise<number> { throw new NotConfigured("Mollak"); }
  async getBudget(): Promise<MollakBudget> { throw new NotConfigured("Mollak"); }
}
export class LiveUtilityBillService implements UtilityBillService {
  async fetchBill(): Promise<UtilityBillInfo> { throw new NotConfigured("Utility bill"); }
  async payBill(): Promise<{ supported: boolean; message: string }> { throw new NotConfigured("Utility bill"); }
}
export class LiveEmailService implements EmailService {
  async send(): Promise<void> { throw new NotConfigured("Email"); }
}

// -------------------------------------------------------------- selection
const live = (k: string) => process.env[k] === "live";
export const ejari = (): EjariService => (live("EJARI_MODE") ? new LiveEjariService() : new MockEjariService());
export const mollak = (): MollakService => (live("MOLLAK_MODE") ? new LiveMollakService() : new MockMollakService());
export const utilities = (): UtilityBillService => (live("UTILITY_MODE") ? new LiveUtilityBillService() : new MockUtilityBillService());
export const email = (): EmailService => (live("EMAIL_MODE") ? new LiveEmailService() : new MockEmailService());

/** Feature flags, e.g. FF_EJARI=false disables the callable. Default on. */
export const flagOn = (k: string) => process.env[k] !== "false";
