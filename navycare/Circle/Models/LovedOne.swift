// LovedOne.swift
// navycare — Circle Feature
//
// The person at the center of the care circle.

import Foundation

/// Represents the person whose care is being coordinated.
struct LovedOne: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var profileImageURL: URL?
    var status: String
    var isOnline: Bool

    var initials: String {
        name.components(separatedBy: " ")
            .compactMap(\.first)
            .prefix(2)
            .map(String.init)
            .joined()
            .uppercased()
    }

    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }
}

// MARK: - Mock

extension LovedOne {
    static let mock = LovedOne(
        id: UUID(),
        name: "Margaret Anderson",
        profileImageURL: nil,
        status: "Feeling well today ✨",
        isOnline: true
    )
}
