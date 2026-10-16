//
//  MovementDraft.swift
//  BudgetSpy
//

import Foundation

/// Values being edited in the movement form. The amount is always unsigned.
struct MovementDraft: Equatable {
    var kind: MovementKind = .expense
    var amount: Decimal = 0
    var description = ""
    var date = Calendar.current.startOfDay(for: .now)
    var originAccountID: UUID?
    var destinationAccountID: UUID?
}

extension MovementDraft {
    init(movement: Movement) {
        self.init(
            kind: movement.kind,
            amount: movement.amountValue.magnitude,
            description: movement.movementDescription ?? "",
            date: movement.date ?? Calendar.current.startOfDay(for: .now),
            originAccountID: movement.originAccount?.id,
            destinationAccountID: movement.destinationAccount?.id
        )
    }
}
