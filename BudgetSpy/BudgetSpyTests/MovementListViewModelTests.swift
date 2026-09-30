//
//  MovementListViewModelTests.swift
//  BudgetSpyTests
//

import CoreData
import Testing
@testable import BudgetSpy

@MainActor
struct MovementListViewModelTests {
    private let context = makeInMemoryContext()

    private func create(_ kind: MovementKind, _ amount: Decimal, from origin: Account) throws -> Movement {
        let movement = try MovementLedger(context: context).create(
            MovementDraft(kind: kind, amount: amount, description: "Compra de café", originAccountID: origin.id)
        )
        try context.save()
        return movement
    }

    @Test func confirmingDeletesTheMovementAndRestoresTheBalance() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let expense = try create(.expense, 10_000, from: payroll)
        let viewModel = MovementListViewModel(context: context)

        viewModel.requestDeletion(of: expense)
        #expect(viewModel.deletionConfirmationIsPresented)
        #expect(viewModel.deletionConfirmationTitle == "¿Eliminar el movimiento «Compra de café»?")

        viewModel.confirmDeletion(of: expense)

        #expect(payroll.balanceValue == 100_000)
        #expect(try fetchAll(Movement.self, in: context).count == 1)
        #expect(viewModel.movementPendingDeletion == nil)
        #expect(viewModel.blockedDeletionIsPresented == false)
        #expect(viewModel.deleteErrorIsPresented == false)
    }

    @Test func cancellingChangesNothing() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let expense = try create(.expense, 10_000, from: payroll)
        let viewModel = MovementListViewModel(context: context)

        viewModel.requestDeletion(of: expense)
        viewModel.cancelDeletion()

        #expect(viewModel.deletionConfirmationIsPresented == false)
        #expect(payroll.balanceValue == 90_000)
        #expect(try fetchAll(Movement.self, in: context).count == 2)
    }

    @Test func blockedDeletionShowsTheJustification() throws {
        let payroll = try insertAccount("Nómina", in: context)
        let income = try create(.income, 50_000, from: payroll)
        _ = try create(.expense, 20_000, from: payroll)
        let viewModel = MovementListViewModel(context: context)

        viewModel.confirmDeletion(of: income)

        #expect(viewModel.blockedDeletionIsPresented)
        #expect(viewModel.blockedDeletionMessage == "No se puede eliminar el movimiento: el saldo de Nómina quedaría en -$ 20.000,00")
        #expect(payroll.balanceValue == 30_000)
        #expect(income.isDeleted == false)
    }

    @Test func failedSaveShowsTheErrorAndRollsBack() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let expense = try create(.expense, 10_000, from: payroll)
        // A pending movement without required fields makes the next save fail.
        _ = Movement(context: context)
        let viewModel = MovementListViewModel(context: context)

        viewModel.confirmDeletion(of: expense)

        #expect(viewModel.deleteErrorIsPresented)
        #expect(payroll.balanceValue == 90_000)
        #expect(expense.isDeleted == false)
    }
}
