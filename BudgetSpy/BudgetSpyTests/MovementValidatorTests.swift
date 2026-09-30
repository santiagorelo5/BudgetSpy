//
//  MovementValidatorTests.swift
//  BudgetSpyTests
//

import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct MovementValidatorTests {
    private let validator = MovementValidator()
    private let validDraft = MovementDraft(kind: .expense, amount: 10_000, description: "Compra de café", originAccountID: UUID())

    @Test func validDraftHasNoErrors() {
        #expect(validator.errors(for: validDraft).isEmpty)
    }

    @Test func zeroAmount() {
        var draft = validDraft
        draft.amount = 0
        #expect(validator.errors(for: draft) == [.amount: .zeroAmount])
        #expect(MovementValidationError.zeroAmount.message == "Ingresa un valor mayor a 0")
    }

    @Test(arguments: ["", "   "])
    func emptyDescription(description: String) {
        var draft = validDraft
        draft.description = description
        #expect(validator.errors(for: draft) == [.description: .emptyDescription])
        #expect(MovementValidationError.emptyDescription.message == "Ingresa una descripción")
    }

    @Test func missingOrigin() {
        var draft = validDraft
        draft.originAccountID = nil
        #expect(validator.errors(for: draft) == [.originAccount: .missingOriginAccount])
        #expect(MovementValidationError.missingOriginAccount.message == "Selecciona una cuenta")
    }

    @Test func transferWithoutDestination() {
        var draft = validDraft
        draft.kind = .transfer
        #expect(validator.errors(for: draft) == [.destinationAccount: .missingDestinationAccount])
        #expect(MovementValidationError.missingDestinationAccount.message == "Selecciona la cuenta destino")

        draft.destinationAccountID = UUID()
        #expect(validator.errors(for: draft).isEmpty)
    }
}
