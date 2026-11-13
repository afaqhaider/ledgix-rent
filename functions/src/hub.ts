import * as crypto from "crypto";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

/**
 * LedGix ID (LedGix Hub) sign-in for LedGix Rent.
 *
 * The app runs the Authorization Code + PKCE flow against the Hub and sends
 * the resulting code here. This function redeems it at the Hub's token
 * endpoint, verifies the ID token (signature, issuer, audience, expiry) and
 * the access token (/me must return the same subject with a verified email),
 * maps the Hub subject to a Rent user, and returns a Firebase custom token.
 *
 * Links live in ledgixIdentityLinks/{hubSubject}; Firestore rules deny all
 * client access to that collection.
 */
const HUB_ISSUER = "https://auth.getledgix.com";
const HUB_CLIENT_ID = "ledgix-rent";
/** Must match the client's redirect_uris registered in the Hub. */
const REDIRECT_URIS = new Set([
  "com.ledgix.rent://oidc-callback",
  "https://rent.getledgix.com/hub-callback",
  "https://ledgix-rent.web.app/hub-callback",
]);
export const LINKS = "ledgixIdentityLinks";

type Jwk = crypto.JsonWebKey & { kid?: string };
let jwksCache: { expiresAt: number; keys: Jwk[] } = { expiresAt: 0, keys: [] };

const text = (v: unknown) => (typeof v === "string" ? v.trim() : "");
const decode = (segment: string) => JSON.parse(Buffer.from(segment, "base64url").toString("utf8"));

async function hubJwks(): Promise<Jwk[]> {
  if (jwksCache.expiresAt > Date.now()) return jwksCache.keys;
  const res = await fetch(`${HUB_ISSUER}/jwks`);
  if (!res.ok) throw new Error(`Hub JWKS returned ${res.status}`);
  const body = (await res.json()) as { keys?: Jwk[] };
  if (!Array.isArray(body.keys)) throw new Error("Hub JWKS is invalid");
  jwksCache = { expiresAt: Date.now() + 10 * 60 * 1000, keys: body.keys };
  return body.keys;
}

/** Verifies a Hub ID token and returns its subject. */
async function verifyIdToken(raw: string): Promise<string> {
  const parts = raw.split(".");
  if (parts.length !== 3) throw new Error("Malformed JWT");
  const header = decode(parts[0]);
  const payload = decode(parts[1]);
  if (!["RS256", "PS256"].includes(header.alg)) throw new Error("Unsupported JWT algorithm");
  const jwk = (await hubJwks()).find((k) => k.kid === header.kid);
  if (!jwk) throw new Error("Unknown JWT signing key");
  const key = crypto.createPublicKey({ key: jwk, format: "jwk" });
  const verified = crypto.verify(
    "sha256",
    Buffer.from(`${parts[0]}.${parts[1]}`),
    header.alg === "PS256"
      ? { key, padding: crypto.constants.RSA_PKCS1_PSS_PADDING, saltLength: 32 }
      : { key, padding: crypto.constants.RSA_PKCS1_PADDING },
    Buffer.from(parts[2], "base64url"),
  );
  const aud: unknown[] = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
  const now = Math.floor(Date.now() / 1000);
  if (!verified || payload.iss !== HUB_ISSUER || !aud.includes(HUB_CLIENT_ID) || !(payload.exp > now)) {
    throw new Error("JWT claims are invalid");
  }
  const subject = text(payload.sub);
  if (!subject) throw new Error("Hub identity is missing a subject");
  return subject;
}

/** Redeems the authorization code and returns the verified Hub identity. */
async function hubIdentity(code: string, verifier: string, redirectUri: string) {
  const tokenRes = await fetch(`${HUB_ISSUER}/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      code,
      redirect_uri: redirectUri,
      client_id: HUB_CLIENT_ID,
      code_verifier: verifier,
    }),
  });
  if (!tokenRes.ok) {
    logger.warn("Hub token exchange failed", { status: tokenRes.status });
    throw new HttpsError("unauthenticated", "LedGix ID sign-in expired or was already used. Please try again.");
  }
  const tokens = (await tokenRes.json()) as { id_token?: string; access_token?: string };
  if (!tokens.id_token || !tokens.access_token) {
    throw new HttpsError("unauthenticated", "LedGix ID returned an incomplete session.");
  }

  let subject: string;
  try {
    subject = await verifyIdToken(tokens.id_token);
  } catch (error) {
    logger.warn("Hub ID token verification failed", { reason: (error as Error).message });
    throw new HttpsError("unauthenticated", "LedGix ID sign-in could not be verified.");
  }

  const meRes = await fetch(`${HUB_ISSUER}/me`, {
    headers: { Authorization: `Bearer ${tokens.access_token}`, Accept: "application/json" },
  });
  if (!meRes.ok) throw new HttpsError("unauthenticated", "LedGix ID session could not be verified.");
  const me = (await meRes.json()) as { sub?: string; email?: string; email_verified?: boolean; name?: string };
  const email = text(me.email).toLowerCase();
  if (text(me.sub) !== subject || !email || me.email_verified !== true) {
    throw new HttpsError("failed-precondition", "Verify your LedGix ID email before signing in to LedGix Rent.");
  }
  return { subject, email, name: text(me.name) };
}

export const exchangeLedgixHubSession = onCall(async (req) => {
  const code = text(req.data?.code);
  const verifier = text(req.data?.verifier);
  const redirectUri = text(req.data?.redirectUri);
  if (!code || !verifier || !REDIRECT_URIS.has(redirectUri)) {
    throw new HttpsError("invalid-argument", "code, verifier and a registered redirectUri are required.");
  }
  const hub = await hubIdentity(code, verifier, redirectUri);

  const auth = getAuth();
  const db = getFirestore();
  const linkRef = db.collection(LINKS).doc(hub.subject);
  const link = await linkRef.get();

  let uid: string | undefined;
  if (link.exists) {
    const linked = await auth.getUser(String(link.get("localUid"))).catch(() => null);
    uid = linked?.uid;
  }
  if (!uid) {
    const existing = await auth.getUserByEmail(hub.email).catch(() => null);
    if (existing) {
      // Never take over an account whose owner hasn't proved the email.
      if (!existing.emailVerified) {
        throw new HttpsError(
          "failed-precondition",
          "A LedGix Rent account already uses this email. Sign in with your password, or verify that email first.",
        );
      }
      uid = existing.uid;
    } else {
      const created = await auth.createUser({
        email: hub.email,
        emailVerified: true,
        ...(hub.name ? { displayName: hub.name } : {}),
      });
      uid = created.uid;
    }
  }

  await db.runTransaction(async (tx) => {
    const current = await tx.get(linkRef);
    if (current.exists && current.get("localUid") !== uid) {
      // Previous link pointed at a deleted user; replace it.
      logger.info("Relinking Hub subject", { subject: hub.subject });
    }
    tx.set(
      linkRef,
      {
        localUid: uid,
        email: hub.email,
        linkedAt: current.exists ? current.get("linkedAt") : FieldValue.serverTimestamp(),
        lastSignInAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  return { customToken: await auth.createCustomToken(uid, { ledgixHubSubject: hub.subject }) };
});
