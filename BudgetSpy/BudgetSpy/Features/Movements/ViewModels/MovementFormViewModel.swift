//
//  MovementFormViewModel.swift
//  BudgetSpy
//

import CoreData
import Observation
import OSLog

@Observable
final class MovementFormViewModel {
    static let noAccountsMessage = "No hay cuentas disponibles"

    private(set) var draft: MovementDraft
    /// Only fields the user already modified show their error.
    private(set) var editedFields: Set<MovementField> = []
    var saveErrorIsPresented = false

    /// Accounts in carousel order (oldest first).
    let accounts: [AccountSnapshot]

    private let initialDraft: MovementDraft
    private let originalEffect: MovementEffect?
    private let route: MovementFormRoute
    private let context: NSManagedObjectContext
    private let rules: MovementRules
    private let validator: MovementValidator
    private let logger = Logger(subsystem: "BudgetSpy", category: "MovementForm")

    init(
        route: MovementFormRoute,
        context: NSManagedObjectContext,
        rules: MovementRules = MovementRules(),
        validator: MovementValidator = MovementValidator()
    ) {
        let accounts = Self.fetchAccounts(in: context)
        let draft = switch route {
        case .create(let originAccountID):
            MovementDraft(originAccountID: accounts.first { $0.id == originAccountID }?.id ?? accounts.first?.id)
        case .edit(let movement): MovementDraft(movement: movement)
        }
        self.accounts = accounts
        self.draft = draft
        self.initialDraft = draft
        self.originalEffect = if case .edit(let movement) = route { movement.effect } else { nil }
        self.route = route
        self.context = context
        self.rules = rules
        self.validator = validator
    }

    var isEditing: Bool {
        if case .edit = route { return true }
        return false
    }

    var navigationTitle: String {
        isEditing ? "Editar movimiento" : "Nuevo movimiento"
    }

    var primaryButtonTitle: String {
        isEditing ? "Guardar cambios" : "Crear movimiento"
    }

    var saveErrorMessage: String {
        isEditing ? "No se pudieron guardar los cambios. Intenta de nuevo." : "No se pudo crear el movimiento. Intenta de nuevo."
    }

    var originFieldTitle: String {
        draft.kind == .transfer ? "Cuenta origen" : "Cuenta"
    }

    var showsDestination: Bool {
        draft.kind == .transfer
    }

    /// Transfers can only leave from savings accounts.
    var originOptions: [AccountSnapshot] {
        draft.kind == .transfer ? accounts.filter { $0.kind == .savings } : accounts
    }

    var destinationOptions: [AccountSnapshot] {
        accounts.filter { $0.id != draft.originAccountID }
    }

    var errors: [MovementField: MovementValidationError] {
        validator.errors(for: draft)
    }

    var balanceError: MovementBalanceError? {
        guard let effect = MovementEffect(draft: draft), rules.isAllowed(effect, accounts: accountsByID) else { return nil }
        return rules.balanceError(applying: effect, replacing: originalEffect, accounts: accountsByID)
    }

    var canSave: Bool {
        guard errors.isEmpty, let effect = MovementEffect(draft: draft) else { return false }
        return rules.isAllowed(effect, accounts: accountsByID) && balanceError == nil
    }

    var hasChanges: Bool {
        draft != initialDraft
    }

    func visibleError(for field: MovementField) -> String? {
        if editedFields.contains(field), let error = errors[field] {
            return error.message
        }
        // Balance errors can come from changing any field, e.g. the kind.
        if field == .amount, hasChanges {
            return balanceError?.message
        }
        return nil
    }

    func select(kind: MovementKind) {
        guard kind != draft.kind else { return }
        draft.kind = kind
        if kind == .transfer {
            if !originOptions.contains(where: { $0.id == draft.originAccountID }) {
                draft.originAccountID = originOptions.first?.id
            }
            draft.destinationAccountID = destinationOptions.first?.id
        } else {
            draft.destinationAccountID = nil
            if draft.originAccountID == nil {
                draft.originAccountID = originOptions.first?.id
            }
        }
    }

    func updateAmount(_ amount: Decimal) {
        draft.amount = amount
        editedFields.insert(.amount)
    }

    func updateDescription(_ description: String) {
        draft.description = String(description.prefix(MovementValidator.maximumDescriptionLength))
        editedFields.insert(.description)
    }

    func updateDate(_ date: Date) {
        draft.date = Calendar.current.startOfDay(for: min(date, .now))
    }

    func selectOrigin(_ accountID: UUID?) {
        draft.originAccountID = accountID
        editedFields.insert(.originAccount)
        if draft.kind == .transfer, draft.destinationAccountID == accountID {
            draft.destinationAccountID = destinationOptions.first?.id
        }
    }

    func selectDestination(_ accountID: UUID?) {
        draft.destinationAccountID = accountID
        editedFields.insert(.destinationAccount)
    }

    /// Returns the origin account of the saved movement; on failure it shows the save error.
    func save() -> UUID? {
        guard canSave else { return nil }
        let ledger = MovementLedger(context: context, rules: rules)
        do {
            switch route {
            case .create: try ledger.create(draft)
            case .edit(let movement): try ledger.update(movement, with: draft)
            }
            try context.save()
            return draft.originAccountID
        } catch {
            logger.error("No se pudo guardar el movimiento: \(error)")
            context.rollback()
            saveErrorIsPresented = true
            return nil
        }
    }

    private var accountsByID: MovementRules.Accounts {
        Dictionary(accounts.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func fetchAccounts(in context: NSManagedObjectContext) -> [AccountSnapshot] {
        let request: NSFetchRequest<Account> = Account.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Account.createdAt, ascending: true)]
        let accounts = (try? context.fetch(request)) ?? []
        return accounts.compactMap(AccountSnapshot.init(account:))
    }
}
