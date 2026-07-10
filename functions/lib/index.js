"use strict";
// index.ts
// navycare — Cloud Functions
//
// Entry point. Initializes Firebase Admin and exports all functions.
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
exports.onUserCreated = exports.removeCaregiver = exports.expireInvitations = exports.revokeInvitation = exports.acceptInvitation = exports.validateInvitationToken = exports.createInvitation = void 0;
const admin = __importStar(require("firebase-admin"));
// Initialize Admin SDK once
admin.initializeApp();
// Re-export all callable functions
var invitations_1 = require("./invitations");
Object.defineProperty(exports, "createInvitation", { enumerable: true, get: function () { return invitations_1.createInvitation; } });
Object.defineProperty(exports, "validateInvitationToken", { enumerable: true, get: function () { return invitations_1.validateInvitationToken; } });
Object.defineProperty(exports, "acceptInvitation", { enumerable: true, get: function () { return invitations_1.acceptInvitation; } });
Object.defineProperty(exports, "revokeInvitation", { enumerable: true, get: function () { return invitations_1.revokeInvitation; } });
Object.defineProperty(exports, "expireInvitations", { enumerable: true, get: function () { return invitations_1.expireInvitations; } });
var circle_1 = require("./circle");
Object.defineProperty(exports, "removeCaregiver", { enumerable: true, get: function () { return circle_1.removeCaregiver; } });
Object.defineProperty(exports, "onUserCreated", { enumerable: true, get: function () { return circle_1.onUserCreated; } });
//# sourceMappingURL=index.js.map