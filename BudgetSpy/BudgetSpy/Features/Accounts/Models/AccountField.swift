//
//  AccountField.swift
//  BudgetSpy
//

enum AccountField: Hashable, CaseIterable {
    case name
    case lastFourDigits
    case balance
    case creditLimit
}

enum AccountValidationError: Equatable {
    case emptyName
    case nameTooLong
    case incompleteLastFourDigits
    case negativeBalance
    case missingCreditLimit
    case creditLimitBelowDebt

    var message: String {
        switch self {
        case .emptyName: "Ingresa un nombre"
        case .nameTooLong: "El nombre puede tener máximo \(AccountValidator.maximumNameLength) caracteres"
        case .incompleteLastFourDigits: "Ingresa los últimos 4 dígitos"
        case .negativeBalance: "El valor no puede ser negativo"
        case .missingCreditLimit: "Ingresa un límite mayor a 0"
        case .creditLimitBelowDebt: "El límite debe ser mayor o igual a la deuda"
        }
    }
}
