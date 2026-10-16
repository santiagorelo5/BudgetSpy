//
//  MovementKind.swift
//  BudgetSpy
//

/// Behavior of a movement type, resolved from its name.
enum MovementKind: String, CaseIterable, Identifiable {
    case expense = "Gasto"
    case income = "Ingreso"
    case transfer = "Transferencia"

    var id: String { rawValue }

    var displayName: String { rawValue }
}
