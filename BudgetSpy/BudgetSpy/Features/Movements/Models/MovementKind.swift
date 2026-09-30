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

    var systemImage: String {
        switch self {
        case .expense: "arrow.up.right.circle.fill"
        case .income: "arrow.down.left.circle.fill"
        case .transfer: "arrow.left.arrow.right.circle.fill"
        }
    }
}
