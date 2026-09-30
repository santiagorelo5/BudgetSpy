//
//  MovementEffect.swift
//  BudgetSpy
//

import Foundation

/// What a movement does to the balances: its kind, its unsigned amount and the accounts it touches.
struct MovementEffect: Equatable {
    let kind: MovementKind
    let amount: Decimal
    let originID: UUID
    let destinationID: UUID?

    var accountIDs: [UUID] {
        [originID] + (destinationID.map { [$0] } ?? [])
    }
}

extension MovementEffect {
    /// `nil` while the draft has no origin account.
    init?(draft: MovementDraft) {
        guard let originID = draft.originAccountID else { return nil }
        self.init(
            kind: draft.kind,
            amount: draft.amount,
            originID: originID,
            destinationID: draft.kind == .transfer ? draft.destinationAccountID : nil
        )
    }
}
