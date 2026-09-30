//
//  MovementFormViewModelTests.swift
//  BudgetSpyTests
//

import CoreData
import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct MovementFormViewModelTests {
    private let context = makeInMemoryContext()

    private func date(minutesAgo minutes: Double) -> Date {
        .now.addingTimeInterval(-minutes * 60)
    }

    /// Carousel order: Visa (credit card), Nómina, Ahorros casa.
    private func insertThreeAccounts() throws -> (visa: Account, payroll: Account, house: Account) {
        let visa = try insertAccount("Visa", kind: .creditCard, balance: 100_000, createdAt: date(minutesAgo: 3), in: context)
        let payroll = try insertAccount("Nómina", balance: 100_000, createdAt: date(minutesAgo: 2), in: context)
        let house = try insertAccount("Ahorros casa", createdAt: date(minutesAgo: 1), in: context)
        return (visa, payroll, house)
    }

    private func fill(_ viewModel: MovementFormViewModel, amount: Decimal = 10_000) {
        viewModel.updateAmount(amount)
        viewModel.updateDescription("Compra de café")
    }

    // MARK: - Defaults (CA2, CA3, CA12)

    @Test func createStartsWithExpenseTodayAndFirstAccount() throws {
        let accounts = try insertThreeAccounts()
        let viewModel = MovementFormViewModel(route: .create, context: context)

        #expect(viewModel.draft.kind == .expense)
        #expect(viewModel.draft.date == Calendar.current.startOfDay(for: .now))
        #expect(viewModel.draft.originAccountID == accounts.visa.id)
        #expect(viewModel.showsDestination == false)
        #expect(viewModel.originFieldTitle == "Cuenta")
        #expect(viewModel.primaryButtonTitle == "Crear movimiento")
        #expect(viewModel.canSave == false)
        for field in MovementField.allCases {
            #expect(viewModel.visibleError(for: field) == nil)
        }
    }

    @Test func withoutAccountsNothingIsSelectedAndCannotSave() {
        let viewModel = MovementFormViewModel(route: .create, context: context)
        fill(viewModel)

        #expect(viewModel.draft.originAccountID == nil)
        #expect(viewModel.originOptions.isEmpty)
        #expect(viewModel.canSave == false)
    }

    // MARK: - Account selection (CA4, CA5, CA6)

    @Test func transferOffersSavingsAsOriginAndOthersAsDestination() throws {
        let accounts = try insertThreeAccounts()
        let viewModel = MovementFormViewModel(route: .create, context: context)

        viewModel.select(kind: .transfer)

        #expect(viewModel.originFieldTitle == "Cuenta origen")
        #expect(viewModel.showsDestination)
        #expect(viewModel.originOptions.map(\.id) == [accounts.payroll.id, accounts.house.id])
        #expect(viewModel.destinationOptions.map(\.id) == [accounts.visa.id, accounts.house.id])
    }

    @Test func switchingToTransferFromCreditCardPicksFirstSavingsAndFirstOtherAccount() throws {
        let accounts = try insertThreeAccounts()
        let viewModel = MovementFormViewModel(route: .create, context: context)
        #expect(viewModel.draft.originAccountID == accounts.visa.id)

        viewModel.select(kind: .transfer)

        #expect(viewModel.draft.originAccountID == accounts.payroll.id)
        #expect(viewModel.draft.destinationAccountID == accounts.visa.id)
    }

    @Test func choosingTheDestinationAsOriginReassignsTheDestination() throws {
        let accounts = try insertThreeAccounts()
        let viewModel = MovementFormViewModel(route: .create, context: context)
        viewModel.select(kind: .transfer)
        viewModel.selectDestination(accounts.house.id)

        viewModel.selectOrigin(accounts.house.id)

        #expect(viewModel.draft.destinationAccountID == accounts.visa.id)
    }

    @Test func switchingBackToExpenseDiscardsTheDestination() throws {
        let accounts = try insertThreeAccounts()
        let viewModel = MovementFormViewModel(route: .create, context: context)
        viewModel.select(kind: .transfer)
        fill(viewModel)

        viewModel.select(kind: .expense)
        #expect(viewModel.showsDestination == false)
        #expect(viewModel.draft.destinationAccountID == nil)
        #expect(viewModel.save() == accounts.payroll.id)

        let movement = try #require(try fetchAll(Movement.self, in: context).first { $0.movementDescription == "Compra de café" })
        #expect(movement.destinationAccount == nil)
        #expect(movement.kind == .expense)
    }

    @Test func transferWithoutSavingsCannotBeSaved() throws {
        try insertAccount("Visa", kind: .creditCard, balance: 100_000, in: context)
        let viewModel = MovementFormViewModel(route: .create, context: context)
        fill(viewModel)

        viewModel.select(kind: .transfer)

        #expect(viewModel.originOptions.isEmpty)
        #expect(viewModel.draft.originAccountID == nil)
        #expect(viewModel.canSave == false)
    }

    @Test func transferWithoutAnotherAccountCannotBeSaved() throws {
        try insertAccount("Nómina", balance: 100_000, in: context)
        let viewModel = MovementFormViewModel(route: .create, context: context)
        fill(viewModel)

        viewModel.select(kind: .transfer)

        #expect(viewModel.destinationOptions.isEmpty)
        #expect(viewModel.draft.destinationAccountID == nil)
        #expect(viewModel.canSave == false)
    }

    // MARK: - Fields and errors

    @Test func descriptionIsTruncatedToTwentyCharacters() {
        let viewModel = MovementFormViewModel(route: .create, context: context)
        viewModel.updateDescription(String(repeating: "a", count: 25))
        #expect(viewModel.draft.description.count == 20)
    }

    @Test func futureDatesAreNotAccepted() {
        let viewModel = MovementFormViewModel(route: .create, context: context)
        let pastDate = Calendar.current.date(byAdding: .day, value: -46, to: .now)!

        viewModel.updateDate(pastDate)
        #expect(viewModel.draft.date == Calendar.current.startOfDay(for: pastDate))

        viewModel.updateDate(Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        #expect(viewModel.draft.date == Calendar.current.startOfDay(for: .now))
    }

    @Test func editedFieldsShowTheirErrors() throws {
        try insertThreeAccounts()
        let viewModel = MovementFormViewModel(route: .create, context: context)

        viewModel.updateAmount(10_000)
        viewModel.updateAmount(0)
        viewModel.updateDescription("   ")

        #expect(viewModel.visibleError(for: .amount) == "Ingresa un valor mayor a 0")
        #expect(viewModel.visibleError(for: .description) == "Ingresa una descripción")
        #expect(viewModel.canSave == false)
    }

    @Test func balanceErrorIsShownUnderTheAmount() throws {
        let payroll = try insertAccount("Nómina", balance: 50_000, in: context)
        let viewModel = MovementFormViewModel(route: .create, context: context)
        fill(viewModel, amount: 60_000)

        #expect(viewModel.visibleError(for: .amount) == "Saldo insuficiente en Nómina. Disponible: $ 50.000,00")
        #expect(viewModel.canSave == false)

        viewModel.updateAmount(50_000)
        #expect(viewModel.visibleError(for: .amount) == nil)
        #expect(viewModel.save() == payroll.id)
        #expect(payroll.balanceValue == 0)
    }

    // MARK: - Changes (CA13)

    @Test func hasChangesIsFalseWhenOpenedAndAfterReverting() throws {
        try insertThreeAccounts()
        let viewModel = MovementFormViewModel(route: .create, context: context)
        #expect(viewModel.hasChanges == false)

        viewModel.updateDescription("Café")
        #expect(viewModel.hasChanges)

        viewModel.updateDescription("")
        #expect(viewModel.hasChanges == false)
    }

    // MARK: - Editing (CA12, CA23, CA37)

    @Test func editingChangesExpenseToIncome() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let movement = try MovementLedger(context: context).create(
            MovementDraft(kind: .expense, amount: 10_000, description: "Compra de café", originAccountID: payroll.id)
        )
        try context.save()

        let viewModel = MovementFormViewModel(route: .edit(movement), context: context)
        #expect(viewModel.primaryButtonTitle == "Guardar cambios")
        #expect(viewModel.draft.amount == 10_000)
        #expect(viewModel.hasChanges == false)

        viewModel.select(kind: .income)
        #expect(viewModel.save() == payroll.id)
        #expect(payroll.balanceValue == 110_000)
    }

    @Test func invalidEditCannotBeSaved() throws {
        let payroll = try insertAccount("Nómina", in: context)
        let ledger = MovementLedger(context: context)
        let income = try ledger.create(MovementDraft(kind: .income, amount: 50_000, description: "Sueldo", originAccountID: payroll.id))
        try ledger.create(MovementDraft(kind: .expense, amount: 40_000, description: "Arriendo", originAccountID: payroll.id))
        try context.save()

        let viewModel = MovementFormViewModel(route: .edit(income), context: context)
        viewModel.select(kind: .expense)

        #expect(viewModel.visibleError(for: .amount) == "Saldo insuficiente en Nómina. Disponible: -$ 40.000,00")
        #expect(viewModel.canSave == false)
        #expect(viewModel.save() == nil)
        #expect(payroll.balanceValue == 10_000)
    }

    // MARK: - Save failure

    @Test(arguments: [false, true])
    func failedSaveShowsTheRightMessageAndKeepsBalances(isEditing: Bool) throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let movement = try MovementLedger(context: context).create(
            MovementDraft(kind: .expense, amount: 10_000, description: "Compra de café", originAccountID: payroll.id)
        )
        try context.save()
        let viewModel = MovementFormViewModel(route: isEditing ? .edit(movement) : .create, context: context)
        fill(viewModel, amount: 20_000)
        try fetchAll(MovementType.self, in: context).forEach(context.delete)

        #expect(viewModel.save() == nil)

        #expect(viewModel.saveErrorIsPresented)
        #expect(viewModel.saveErrorMessage == (isEditing
            ? "No se pudieron guardar los cambios. Intenta de nuevo."
            : "No se pudo crear el movimiento. Intenta de nuevo."))
        #expect(payroll.balanceValue == 90_000)
    }
}
