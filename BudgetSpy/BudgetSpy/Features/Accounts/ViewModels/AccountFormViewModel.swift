//
//  AccountFormViewModel.swift
//  BudgetSpy
//

import CoreData
import Observation
import OSLog

@Observable
final class AccountFormViewModel {
    private(set) var draft: AccountDraft
    /// Only fields the user already modified show their error.
    private(set) var editedFields: Set<AccountField> = []
    var saveErrorIsPresented = false

    private let initialDraft: AccountDraft
    private let route: AccountFormRoute
    private let context: NSManagedObjectContext
    private let validator: AccountValidator
    private let logger = Logger(subsystem: "BudgetSpy", category: "AccountForm")

    init(route: AccountFormRoute, context: NSManagedObjectContext, validator: AccountValidator = AccountValidator()) {
        let draft = switch route {
        case .create: AccountDraft()
        case .edit(let account): AccountDraft(account: account)
        }
        self.draft = draft
        self.initialDraft = draft
        self.route = route
        self.context = context
        self.validator = validator
    }

    var isEditing: Bool {
        if case .edit = route { return true }
        return false
    }

    var isKindLocked: Bool { isEditing }

    var navigationTitle: String {
        isEditing ? "Editar cuenta" : "Nueva cuenta"
    }

    var primaryButtonTitle: String {
        isEditing ? "Guardar cambios" : "Crear cuenta"
    }

    var errors: [AccountField: AccountValidationError] {
        validator.errors(for: draft)
    }

    var canSave: Bool {
        errors.isEmpty
    }

    var hasChanges: Bool {
        draft != initialDraft
    }

    var cardContent: AccountCardContent {
        AccountCardContent(draft: draft)
    }

    func visibleError(for field: AccountField) -> AccountValidationError? {
        editedFields.contains(field) ? errors[field] : nil
    }

    func select(kind: AccountKind) {
        guard !isKindLocked else { return }
        draft.kind = kind
        if !kind.requiresCreditLimit {
            draft.creditLimit = 0
        }
    }

    func updateName(_ name: String) {
        draft.name = String(name.prefix(AccountValidator.maximumNameLength))
        editedFields.insert(.name)
    }

    func updateLastFourDigits(_ digits: String) {
        draft.lastFourDigits = String(digits.filter(\.isASCIIDigit).prefix(AccountValidator.lastFourDigitsLength))
        editedFields.insert(.lastFourDigits)
    }

    func updateBalance(_ balance: Decimal) {
        draft.balance = balance
        editedFields.insert(.balance)
    }

    func updateCreditLimit(_ creditLimit: Decimal) {
        draft.creditLimit = creditLimit
        editedFields.insert(.creditLimit)
    }

    /// Returns `true` when the account was saved; on failure it shows the save error.
    @discardableResult
    func save() -> Bool {
        guard canSave else { return false }
        do {
            let account = try accountToSave()
            account.name = draft.name
            account.lastFourDigits = draft.lastFourDigits
            account.creditLimitValue = draft.kind.requiresCreditLimit ? draft.creditLimit : nil
            try recordBalance(of: account)
            try context.save()
            return true
        } catch {
            logger.error("No se pudo guardar la cuenta: \(error)")
            context.rollback()
            saveErrorIsPresented = true
            return false
        }
    }

    /// The balance only changes through the ledger, which records the matching movement.
    private func recordBalance(of account: Account) throws {
        let ledger = MovementLedger(context: context)
        switch route {
        case .create: try ledger.recordInitialBalance(for: account, balance: draft.balance)
        case .edit: try ledger.recordAdjustment(for: account, to: draft.balance)
        }
    }

    private func accountToSave() throws -> Account {
        switch route {
        case .create:
            guard let accountType = try AccountType.find(draft.kind, in: context) else {
                throw AccountFormError.missingAccountType(draft.kind)
            }
            let account = Account(context: context)
            account.id = UUID()
            account.createdAt = .now
            account.accountType = accountType
            return account
        case .edit(let account):
            return account
        }
    }
}

private enum AccountFormError: Error {
    case missingAccountType(AccountKind)
}
