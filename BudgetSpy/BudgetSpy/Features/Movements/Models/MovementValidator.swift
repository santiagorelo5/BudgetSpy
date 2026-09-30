//
//  MovementValidator.swift
//  BudgetSpy
//

import Foundation

/// Field rules of a movement. Balance rules live in `MovementRules`.
struct MovementValidator {
    static let maximumDescriptionLength = 20

    func errors(for draft: MovementDraft) -> [MovementField: MovementValidationError] {
        var errors: [MovementField: MovementValidationError] = [:]
        if draft.amount <= 0 {
            errors[.amount] = .zeroAmount
        }
        if draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors[.description] = .emptyDescription
        }
        if draft.originAccountID == nil {
            errors[.originAccount] = .missingOriginAccount
        }
        if draft.kind == .transfer, draft.destinationAccountID == nil {
            errors[.destinationAccount] = .missingDestinationAccount
        }
        return errors
    }
}
