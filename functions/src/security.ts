// security.ts
// navycare — Cloud Functions
//
// Cryptographic utilities and rate limiting for invitation security.

import * as crypto from "crypto";
import * as admin from "firebase-admin";

// MARK: - Token Utilities

/**
 * Generates a cryptographically secure invitation token.
 * @returns 64-char hex string (256 bits of entropy)
 */
export function generateToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

/**
 * Hashes a plain token with SHA-256.
 * Only the hash is ever stored in Firestore.
 */
export function hashToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}

/**
 * Validates that a token matches a stored hash.
 */
export function verifyToken(plainToken: string, storedHash: string): boolean {
  const hash = hashToken(plainToken);
  // Constant-time comparison to prevent timing attacks
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(storedHash));
}

// MARK: - Rate Limiting

const RATE_LIMIT_MAX   = 10;   // invitations per window
const RATE_LIMIT_HOURS = 24;   // window size in hours

interface RateLimit {
  invitesSentToday: number;
  windowStart:      admin.firestore.Timestamp;
}

/**
 * Checks and increments the invitation rate limit for a user.
 * Throws with code RESOURCE_EXHAUSTED if the limit is exceeded.
 */
export async function checkAndIncrementRateLimit(
  db:  admin.firestore.Firestore,
  uid: string
): Promise<void> {
  const ref = db.collection("rateLimits").doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now  = admin.firestore.Timestamp.now();

    if (!snap.exists) {
      tx.set(ref, {
        invitesSentToday: 1,
        windowStart: now,
      } satisfies RateLimit);
      return;
    }

    const data = snap.data() as RateLimit;
    const windowStart = data.windowStart.toDate();
    const hoursSinceWindow =
      (Date.now() - windowStart.getTime()) / (1000 * 60 * 60);

    if (hoursSinceWindow > RATE_LIMIT_HOURS) {
      // Reset window
      tx.set(ref, { invitesSentToday: 1, windowStart: now } satisfies RateLimit);
      return;
    }

    if (data.invitesSentToday >= RATE_LIMIT_MAX) {
      throw Object.assign(
        new Error("Rate limit exceeded. Max 10 invitations per 24 hours."),
        { code: "resource-exhausted" }
      );
    }

    tx.update(ref, {
      invitesSentToday: admin.firestore.FieldValue.increment(1),
    });
  });
}

// MARK: - Phone Normalization

/**
 * Validates that a string is a plausible E.164 phone number.
 * Full validation is performed by Firebase Phone Auth.
 */
export function isValidE164(phone: string): boolean {
  return /^\+[1-9]\d{7,14}$/.test(phone);
}

// MARK: - Audit Log

export async function writeAuditLog(
  db:         admin.firestore.Firestore,
  action:     string,
  entityType: string,
  entityId:   string,
  actorUID:   string,
  metadata?:  Record<string, unknown>
): Promise<void> {
  await db.collection("auditLogs").add({
    action,
    entityType,
    entityId,
    actorUID,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    metadata:  metadata ?? {},
  });
}
