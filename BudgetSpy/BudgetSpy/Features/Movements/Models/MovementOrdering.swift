//
//  MovementOrdering.swift
//  BudgetSpy
//

import Foundation

/// Order of an account's movement list: newest date first, then the larger signed amount
/// as seen from that account, then the most recently created.
enum MovementOrdering {
    struct Key: Equatable {
        let date: Date
        let signedAmount: Decimal
        let createdAt: Date
    }

    static func areInIncreasingOrder(_ lhs: Key, _ rhs: Key) -> Bool {
        if lhs.date != rhs.date { return lhs.date > rhs.date }
        if lhs.signedAmount != rhs.signedAmount { return lhs.signedAmount > rhs.signedAmount }
        return lhs.createdAt > rhs.createdAt
    }

    static func sorted(_ movements: some Sequence<Movement>, for account: Account) -> [Movement] {
        movements
            .map { (movement: $0, key: key(of: $0, for: account)) }
            .sorted { areInIncreasingOrder($0.key, $1.key) }
            .map(\.movement)
    }

    private static func key(of movement: Movement, for account: Account) -> Key {
        Key(
            date: movement.date ?? .distantPast,
            signedAmount: movement.signedAmount(for: account),
            createdAt: movement.createdAt ?? .distantPast
        )
    }
}
