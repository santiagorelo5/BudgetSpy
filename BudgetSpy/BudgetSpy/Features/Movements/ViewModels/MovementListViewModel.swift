//
//  MovementListViewModel.swift
//  BudgetSpy
//

import CoreData
import Observation
import OSLog

@Observable
final class MovementListViewModel {
    private(set) var movementPendingDeletion: Movement?
    private(set) var blockedDeletionMessage: String?
    var deleteErrorIsPresented = false

    private let context: NSManagedObjectContext
    private let logger = Logger(subsystem: "BudgetSpy", category: "MovementList")

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    var deletionConfirmationIsPresented: Bool {
        get { movementPendingDeletion != nil }
        set {
            if !newValue {
                movementPendingDeletion = nil
            }
        }
    }

    var blockedDeletionIsPresented: Bool {
        get { blockedDeletionMessage != nil }
        set {
            if !newValue {
                blockedDeletionMessage = nil
            }
        }
    }

    var deletionConfirmationTitle: String {
        "¿Eliminar el movimiento «\(movementPendingDeletion?.movementDescription ?? "")»?"
    }

    func requestDeletion(of movement: Movement) {
        movementPendingDeletion = movement
    }

    func cancelDeletion() {
        movementPendingDeletion = nil
    }

    func confirmDeletion(of movement: Movement) {
        movementPendingDeletion = nil
        do {
            try MovementLedger(context: context).delete(movement)
            try context.save()
        } catch MovementLedgerError.deletionBlocked(let error) {
            blockedDeletionMessage = error.message
        } catch {
            logger.error("No se pudo eliminar el movimiento: \(error)")
            context.rollback()
            deleteErrorIsPresented = true
        }
    }
}
