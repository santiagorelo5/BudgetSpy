//
//  AccountCarouselViewModelTests.swift
//  BudgetSpyTests
//

import CoreData
import Testing
@testable import BudgetSpy

@MainActor
struct AccountCarouselViewModelTests {
    private let context = makeInMemoryContext()

    private func insertAccount() throws -> Account {
        let account = Account(context: context)
        account.id = UUID()
        account.name = "Nómina"
        account.lastFourDigits = "4821"
        account.balanceValue = 1_250_000
        account.createdAt = .now
        account.accountType = try AccountType.find(.savings, in: context)
        try context.save()
        return account
    }

    @Test func confirmingDeletesAccountButNotItsType() throws {
        let account = try insertAccount()
        let viewModel = AccountCarouselViewModel(context: context)

        viewModel.requestDeletion(of: account)
        #expect(viewModel.deletionConfirmationIsPresented)
        #expect(viewModel.deletionConfirmationTitle == "¿Eliminar la cuenta «Nómina»?")

        viewModel.confirmDeletion(of: account)

        #expect(try fetchAll(Account.self, in: context).isEmpty)
        #expect(try fetchAll(AccountType.self, in: context).count == 2)
        #expect(viewModel.accountPendingDeletion == nil)
        #expect(viewModel.deleteErrorIsPresented == false)
    }

    @Test func cancellingDeletesNothing() throws {
        let account = try insertAccount()
        let viewModel = AccountCarouselViewModel(context: context)

        viewModel.requestDeletion(of: account)
        viewModel.cancelDeletion()

        #expect(try fetchAll(Account.self, in: context).count == 1)
        #expect(viewModel.deletionConfirmationIsPresented == false)
    }

    @Test func deletingAnAccountConvertsItsTransfersWithoutTouchingOtherBalances() throws {
        let payroll = try BudgetSpyTests.insertAccount("Nómina", balance: 100_000, in: context)
        let house = try BudgetSpyTests.insertAccount("Ahorros casa", balance: 10_000, in: context)
        let ledger = MovementLedger(context: context)
        let transfer = try ledger.create(MovementDraft(
            kind: .transfer, amount: 20_000, description: "Ahorro",
            originAccountID: payroll.id, destinationAccountID: house.id
        ))
        try context.save()
        let viewModel = AccountCarouselViewModel(context: context)

        viewModel.confirmDeletion(of: payroll)

        #expect(viewModel.deleteErrorIsPresented == false)
        #expect(try fetchAll(Account.self, in: context) == [house])
        #expect(transfer.kind == .income)
        #expect(transfer.originAccount == house)
        #expect(house.balanceValue == 30_000)
        #expect(house.originMovementList.count == 2)
    }

    @Test func cancellingKeepsMovements() throws {
        let payroll = try BudgetSpyTests.insertAccount("Nómina", balance: 100_000, in: context)
        let viewModel = AccountCarouselViewModel(context: context)

        viewModel.requestDeletion(of: payroll)
        viewModel.cancelDeletion()

        #expect(payroll.originMovementList.count == 1)
        #expect(payroll.balanceValue == 100_000)
    }
}
