//
//  AccountFormViewModelTests.swift
//  BudgetSpyTests
//

import CoreData
import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct AccountFormViewModelTests {
    private let context = makeInMemoryContext()

    private func makeFilledCreateViewModel(kind: AccountKind = .savings) -> AccountFormViewModel {
        let viewModel = AccountFormViewModel(route: .create, context: context)
        viewModel.select(kind: kind)
        viewModel.updateName("Nómina")
        viewModel.updateLastFourDigits("4821")
        viewModel.updateBalance(1_200_000)
        if kind.requiresCreditLimit {
            viewModel.updateCreditLimit(5_000_000)
        }
        return viewModel
    }

    @Test func createStartsWithSavingsDisabledAndWithoutVisibleErrors() {
        let viewModel = AccountFormViewModel(route: .create, context: context)

        #expect(viewModel.draft.kind == .savings)
        #expect(viewModel.canSave == false)
        #expect(viewModel.primaryButtonTitle == "Crear cuenta")
        #expect(viewModel.isKindLocked == false)
        for field in AccountField.allCases {
            #expect(viewModel.visibleError(for: field) == nil)
        }
    }

    @Test func clearedNameShowsError() {
        let viewModel = AccountFormViewModel(route: .create, context: context)
        viewModel.updateName("Nómina")
        viewModel.updateName("")
        #expect(viewModel.visibleError(for: .name) == .emptyName)
    }

    @Test func switchingBackToSavingsDiscardsCreditLimit() {
        let viewModel = AccountFormViewModel(route: .create, context: context)
        viewModel.select(kind: .creditCard)
        viewModel.updateCreditLimit(3_000_000)

        viewModel.select(kind: .savings)
        #expect(viewModel.draft.creditLimit == 0)

        viewModel.select(kind: .creditCard)
        #expect(viewModel.draft.creditLimit == 0)
    }

    @Test func hasChangesIsFalseWhenOpenedAndAfterReverting() {
        let viewModel = AccountFormViewModel(route: .create, context: context)
        #expect(viewModel.hasChanges == false)

        viewModel.updateName("Nómina")
        #expect(viewModel.hasChanges)

        viewModel.updateName("")
        #expect(viewModel.hasChanges == false)

        viewModel.select(kind: .creditCard)
        viewModel.updateCreditLimit(3_000_000)
        viewModel.select(kind: .savings)
        #expect(viewModel.hasChanges == false)
    }

    @Test func nameIsTruncatedToTwentyCharacters() {
        let viewModel = AccountFormViewModel(route: .create, context: context)
        viewModel.updateName(String(repeating: "a", count: 25))
        #expect(viewModel.draft.name.count == 20)
    }

    @Test func lastFourDigitsKeepsOnlyFourNumbers() {
        let viewModel = AccountFormViewModel(route: .create, context: context)
        viewModel.updateLastFourDigits("48A1")
        #expect(viewModel.draft.lastFourDigits == "481")

        viewModel.updateLastFourDigits("482199")
        #expect(viewModel.draft.lastFourDigits == "4821")
    }

    @Test func saveCreatesSavingsWithoutLimit() throws {
        let viewModel = makeFilledCreateViewModel()

        #expect(viewModel.save())

        let account = try #require(try fetchAll(Account.self, in: context).first)
        #expect(account.name == "Nómina")
        #expect(account.lastFourDigits == "4821")
        #expect(account.balanceValue == 1_200_000)
        #expect(account.creditLimit == nil)
        #expect(account.kind == .savings)
        #expect(account.createdAt != nil)
        #expect(account.id != nil)
    }

    @Test func saveCreatesCreditCardWithLimit() throws {
        let viewModel = makeFilledCreateViewModel(kind: .creditCard)

        #expect(viewModel.save())

        let account = try #require(try fetchAll(Account.self, in: context).first)
        #expect(account.kind == .creditCard)
        #expect(account.balanceValue == 1_200_000)
        #expect(account.creditLimitValue == 5_000_000)
        #expect(account.createdAt != nil)
    }

    @Test func editLocksKindAndUpdatesSameAccount() throws {
        #expect(makeFilledCreateViewModel(kind: .creditCard).save())
        let account = try #require(try fetchAll(Account.self, in: context).first)
        let createdAt = account.createdAt

        let viewModel = AccountFormViewModel(route: .edit(account), context: context)
        #expect(viewModel.isKindLocked)
        #expect(viewModel.primaryButtonTitle == "Guardar cambios")
        #expect(viewModel.hasChanges == false)
        #expect(viewModel.canSave)

        viewModel.select(kind: .savings)
        #expect(viewModel.draft.kind == .creditCard)

        viewModel.updateName("Ahorros casa")
        #expect(viewModel.save())

        let accounts = try fetchAll(Account.self, in: context)
        #expect(accounts.count == 1)
        #expect(accounts.first?.objectID == account.objectID)
        #expect(accounts.first?.name == "Ahorros casa")
        #expect(accounts.first?.createdAt == createdAt)
    }
}
