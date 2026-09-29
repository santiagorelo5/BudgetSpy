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
}
