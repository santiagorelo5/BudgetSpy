//
//  AccountCarouselViewModel.swift
//  BudgetSpy
//

import CoreData
import Observation
import OSLog

@Observable
final class AccountCarouselViewModel {
    private(set) var accountPendingDeletion: Account?
    var deleteErrorIsPresented = false

    private let context: NSManagedObjectContext
    private let logger = Logger(subsystem: "BudgetSpy", category: "AccountCarousel")

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    var deletionConfirmationIsPresented: Bool {
        get { accountPendingDeletion != nil }
        set {
            if !newValue {
                accountPendingDeletion = nil
            }
        }
    }

    var deletionConfirmationTitle: String {
        "¿Eliminar la cuenta «\(accountPendingDeletion?.name ?? "")»?"
    }

    func requestDeletion(of account: Account) {
        accountPendingDeletion = account
    }

    func cancelDeletion() {
        accountPendingDeletion = nil
    }

    func confirmDeletion(of account: Account) {
        accountPendingDeletion = nil
        do {
            try MovementLedger(context: context).prepareDeletion(of: account)
            context.delete(account)
            try context.save()
        } catch {
            logger.error("No se pudo eliminar la cuenta: \(error)")
            context.rollback()
            deleteErrorIsPresented = true
        }
    }
}
