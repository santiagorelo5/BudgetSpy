//
//  MovementBalanceError.swift
//  BudgetSpy
//

import Foundation

/// A movement that would leave a balance below 0 or a debt above the credit limit.
enum MovementBalanceError: Equatable {
    case insufficientFunds(accountName: String, available: Decimal)
    case exceedsCreditLimit(accountName: String, availableCredit: Decimal)
    case exceedsDebt(accountName: String, debt: Decimal)

    var message: String {
        switch self {
        case .insufficientFunds(let name, let available):
            "Saldo insuficiente en \(name). Disponible: \(CurrencyFormatter.string(from: available))"
        case .exceedsCreditLimit(let name, let availableCredit):
            "Supera el límite de \(name). Cupo disponible: \(CurrencyFormatter.string(from: availableCredit))"
        case .exceedsDebt(let name, let debt):
            "El valor supera la deuda de \(name): \(CurrencyFormatter.string(from: debt))"
        }
    }
}

/// A deletion that would leave a balance below 0 or a debt above the credit limit.
enum MovementDeletionError: Equatable {
    case savingsBelowZero(accountName: String, resultingBalance: Decimal)
    case debtBelowZero(accountName: String, resultingDebt: Decimal)
    case debtAboveLimit(accountName: String, resultingDebt: Decimal, creditLimit: Decimal)

    var justification: String {
        switch self {
        case .savingsBelowZero(let name, let balance):
            "el saldo de \(name) quedaría en \(CurrencyFormatter.string(from: balance))"
        case .debtBelowZero(let name, let debt):
            "la deuda de \(name) quedaría en \(CurrencyFormatter.string(from: debt))"
        case .debtAboveLimit(let name, let debt, let limit):
            "la deuda de \(name) quedaría en \(CurrencyFormatter.string(from: debt)) y supera el límite de \(CurrencyFormatter.string(from: limit))"
        }
    }

    var message: String {
        "No se puede eliminar el movimiento: \(justification)"
    }
}
