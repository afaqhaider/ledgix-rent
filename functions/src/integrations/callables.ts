import { HttpsError, onCall } from "firebase-functions/v2/https";
import { ejari, flagOn, mollak, utilities, UtilityProvider } from "./services";

const requireAuth = (auth: unknown) => {
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");
};
const requireFlag = (flag: string) => {
  if (!flagOn(flag)) throw new HttpsError("failed-precondition", `${flag} is switched off in this environment.`);
};

export const ejariLookup = onCall(async (req) => {
  requireAuth(req.auth);
  requireFlag("FF_EJARI");
  const ejariNo = String(req.data?.ejariNo ?? "").trim();
  if (!ejariNo) throw new HttpsError("invalid-argument", "ejariNo is required.");
  return ejari().lookupContract(ejariNo);
});

export const mollakQuery = onCall(async (req) => {
  requireAuth(req.auth);
  requireFlag("FF_MOLLAK");
  const ref = String(req.data?.ref ?? "").trim();
  if (!ref) throw new HttpsError("invalid-argument", "ref is required.");
  const s = mollak();
  switch (req.data?.op) {
    case "charges": return { charges: await s.getServiceCharges(ref) };
    case "balance": return { balance: await s.getOutstandingBalance(ref) };
    case "budget": return s.getBudget(ref);
    default: throw new HttpsError("invalid-argument", "op must be charges, balance or budget.");
  }
});

export const utilityFetch = onCall(async (req) => {
  requireAuth(req.auth);
  requireFlag("FF_UTILITY_BILLS");
  const provider = String(req.data?.provider ?? "") as UtilityProvider;
  const accountNo = String(req.data?.accountNo ?? "").trim();
  if (!provider || !accountNo) throw new HttpsError("invalid-argument", "provider and accountNo are required.");
  return utilities().fetchBill(provider, accountNo);
});
