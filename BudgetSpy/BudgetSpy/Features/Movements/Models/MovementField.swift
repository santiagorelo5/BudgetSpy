//
//  MovementField.swift
//  BudgetSpy
//

enum MovementField: Hashable, CaseIterable {
    case amount
    case description
    case originAccount
    case destinationAccount
}

enum MovementValidationError: Equatable {
    case zeroAmount
    case emptyDescription
    case missingOriginAccount
    case missingDestinationAccount

    var message: String {
        switch self {
        case .zeroAmount: "Ingresa un valor mayor a 0"
        case .emptyDescription: "Ingresa una descripción"
        case .missingOriginAccount: "Selecciona una cuenta"
        case .missingDestinationAccount: "Selecciona la cuenta destino"
        }
    }
}
