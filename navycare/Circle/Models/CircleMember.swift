// CircleMember.swift
// navycare — Circle Feature
//
// Type-erased circle member and orbit slot model.

import Foundation

/// A type-erased member of the care circle.
enum CircleMember: Identifiable, Sendable {
    case lovedOne(LovedOne)
    case caregiver(Caregiver)

    var id: UUID {
        switch self {
        case .lovedOne(let p):  return p.id
        case .caregiver(let p): return p.id
        }
    }

    var name: String {
        switch self {
        case .lovedOne(let p):  return p.name
        case .caregiver(let p): return p.name
        }
    }

    var isOnline: Bool {
        switch self {
        case .lovedOne(let p):  return p.isOnline
        case .caregiver(let p): return p.isOnline
        }
    }
}

// MARK: - Caregiver Slot

/// Represents one of the five orbit positions — either occupied or empty.
enum CaregiverSlot: Identifiable, Sendable {
    case filled(Caregiver)
    case empty(slotIndex: Int)

    var id: String {
        switch self {
        case .filled(let c):    return c.id.uuidString
        case .empty(let index): return "empty_\(index)"
        }
    }

    var orbitIndex: Int {
        switch self {
        case .filled(let c):    return c.orbitPosition
        case .empty(let index): return index
        }
    }

    var caregiver: Caregiver? {
        if case .filled(let c) = self { return c }
        return nil
    }

    var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }
}
