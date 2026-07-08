// CloudFunctionCaller.swift
// navycare — Core
//
// Lightweight client for Firebase Cloud Functions (onCall v2).
// Uses URLSession + Firebase Auth ID token instead of the Functions SDK,
// avoiding an extra SPM dependency.
//
// Callable function request/response envelope:
//   Request body:  { "data": { ...your payload... } }
//   Response body: { "result": { ...function return... } }
//
// Set FIREBASE_PROJECT_ID in Info.plist or via environment config.

import Foundation
import FirebaseAuth

// MARK: - Errors

enum CloudFunctionError: LocalizedError {
    case unauthenticated
    case networkError(String)
    case serverError(code: String, message: String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .unauthenticated:              return "Please sign in to continue."
        case .networkError(let m):          return "Network error: \(m)"
        case .serverError(_, let m):        return m
        case .decodingError(let m):         return "Response error: \(m)"
        }
    }
}

// MARK: - Cloud Function Caller

final class CloudFunctionCaller: @unchecked Sendable {

    static let shared = CloudFunctionCaller()

    /// Firebase project ID — set this to your project's ID.
    /// Override via FIREBASE_PROJECT_ID in Info.plist or at runtime.
    var projectID: String = {
        Bundle.main.object(forInfoDictionaryKey: "FIREBASE_PROJECT_ID") as? String
            ?? "navycare-app"       // fallback — update before deploy
    }()

    var region: String = "us-central1"

    private var baseURL: String {
        "https://\(region)-\(projectID).cloudfunctions.net"
    }

    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Authenticated Call

    /// Calls an `onCall` Cloud Function with Firebase Auth credentials.
    func call<Req: Encodable, Res: Decodable>(
        _ name: String,
        data: Req
    ) async throws -> Res {
        guard let user = Auth.auth().currentUser else {
            throw CloudFunctionError.unauthenticated
        }
        let idToken = try await user.getIDToken()
        return try await perform(name: name, data: data, idToken: idToken)
    }

    // MARK: - Unauthenticated Call (pre-auth functions)

    /// Calls a Cloud Function that doesn't require authentication.
    /// Used for `validateInvitationToken` which is pre-auth by design.
    func callPublic<Req: Encodable, Res: Decodable>(
        _ name: String,
        data: Req
    ) async throws -> Res {
        return try await perform(name: name, data: data, idToken: nil)
    }

    // MARK: - Core HTTP

    private func perform<Req: Encodable, Res: Decodable>(
        name:    String,
        data:    Req,
        idToken: String?
    ) async throws -> Res {
        guard let url = URL(string: "\(baseURL)/\(name)") else {
            throw CloudFunctionError.networkError("Invalid function URL for \(name)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = idToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Wrap in Firebase callable envelope
        let envelope = CallableRequest(data: data)
        request.httpBody = try encoder.encode(envelope)

        let (responseData, response): (Data, URLResponse)
        do {
            (responseData, response) = try await session.data(for: request)
        } catch {
            throw CloudFunctionError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw CloudFunctionError.networkError("No HTTP response")
        }

        // Parse error response
        if !(200..<300).contains(http.statusCode) {
            if let errEnv = try? decoder.decode(CallableErrorResponse.self, from: responseData) {
                throw CloudFunctionError.serverError(
                    code:    errEnv.error.status ?? "UNKNOWN",
                    message: errEnv.error.message
                )
            }
            throw CloudFunctionError.networkError("HTTP \(http.statusCode)")
        }

        // Decode success response
        do {
            let envelope = try decoder.decode(CallableResponse<Res>.self, from: responseData)
            return envelope.result
        } catch {
            throw CloudFunctionError.decodingError(error.localizedDescription)
        }
    }
}

// MARK: - Codable Envelopes

private struct CallableRequest<T: Encodable>: Encodable {
    let data: T
}

private struct CallableResponse<T: Decodable>: Decodable {
    let result: T
}

private struct CallableErrorResponse: Decodable {
    struct ErrorDetail: Decodable {
        let status:  String?
        let message: String
    }
    let error: ErrorDetail
}

// MARK: - Function Payloads & Responses

/// Sent to `validateInvitationToken` (pre-auth).
struct ValidateTokenRequest: Encodable {
    let token: String
}

struct ValidateTokenResponse: Decodable {
    let valid:               Bool
    let status:              String
    let receiverPhoneLast4:  String?
}

/// Sent to `acceptInvitation`.
struct AcceptInvitationRequest: Encodable {
    let token: String
}

struct AcceptInvitationResponse: Decodable {
    let circleId:     String
    let membershipId: String
}
