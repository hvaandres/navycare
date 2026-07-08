"use strict";
// security.ts
// navycare — Cloud Functions
//
// Cryptographic utilities and rate limiting for invitation security.
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateToken = generateToken;
exports.hashToken = hashToken;
exports.verifyToken = verifyToken;
exports.checkAndIncrementRateLimit = checkAndIncrementRateLimit;
exports.isValidE164 = isValidE164;
exports.writeAuditLog = writeAuditLog;
const crypto = __importStar(require("crypto"));
const admin = __importStar(require("firebase-admin"));
// MARK: - Token Utilities
/**
 * Generates a cryptographically secure invitation token.
 * @returns 64-char hex string (256 bits of entropy)
 */
function generateToken() {
    return crypto.randomBytes(32).toString("hex");
}
/**
 * Hashes a plain token with SHA-256.
 * Only the hash is ever stored in Firestore.
 */
function hashToken(token) {
    return crypto.createHash("sha256").update(token).digest("hex");
}
/**
 * Validates that a token matches a stored hash.
 */
function verifyToken(plainToken, storedHash) {
    const hash = hashToken(plainToken);
    // Constant-time comparison to prevent timing attacks
    return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(storedHash));
}
// MARK: - Rate Limiting
const RATE_LIMIT_MAX = 10; // invitations per window
const RATE_LIMIT_HOURS = 24; // window size in hours
/**
 * Checks and increments the invitation rate limit for a user.
 * Throws with code RESOURCE_EXHAUSTED if the limit is exceeded.
 */
async function checkAndIncrementRateLimit(db, uid) {
    const ref = db.collection("rateLimits").doc(uid);
    await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const now = admin.firestore.Timestamp.now();
        if (!snap.exists) {
            tx.set(ref, {
                invitesSentToday: 1,
                windowStart: now,
            });
            return;
        }
        const data = snap.data();
        const windowStart = data.windowStart.toDate();
        const hoursSinceWindow = (Date.now() - windowStart.getTime()) / (1000 * 60 * 60);
        if (hoursSinceWindow > RATE_LIMIT_HOURS) {
            // Reset window
            tx.set(ref, { invitesSentToday: 1, windowStart: now });
            return;
        }
        if (data.invitesSentToday >= RATE_LIMIT_MAX) {
            throw Object.assign(new Error("Rate limit exceeded. Max 10 invitations per 24 hours."), { code: "resource-exhausted" });
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
function isValidE164(phone) {
    return /^\+[1-9]\d{7,14}$/.test(phone);
}
// MARK: - Audit Log
async function writeAuditLog(db, action, entityType, entityId, actorUID, metadata) {
    await db.collection("auditLogs").add({
        action,
        entityType,
        entityId,
        actorUID,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: metadata ?? {},
    });
}
//# sourceMappingURL=security.js.map