//
//  MovementDetailView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

/// Read-only box with every field of a movement, as seen from its origin account.
struct MovementDetailView: View {
    let movement: Movement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(content.kind.displayName, systemImage: content.systemImage)
                .font(.headline)
                .foregroundStyle(content.role.color)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                row("Valor", value: content.formattedAmount, color: content.role.color)
                row("Descripción", value: content.description)
                row("Fecha", value: content.formattedDate)
                row(movement.kind == .transfer ? "Cuenta origen" : "Cuenta", value: movement.originAccount?.name ?? "")
                if let destination = movement.destinationAccount {
                    row("Cuenta destino", value: destination.name ?? "")
                }
            }
        }
        .padding()
        .frame(minWidth: 280, alignment: .leading)
    }

    private var content: MovementRowContent {
        guard let origin = movement.originAccount else {
            return MovementRowContent(kind: movement.kind, description: movement.movementDescription ?? "",
                                      date: movement.date ?? .now, signedAmount: movement.amountValue, role: .outgoing)
        }
        return MovementRowContent(movement: movement, perspective: origin)
    }

    private func row(_ title: String, value: String, color: Color = .primary) -> some View {
        GridRow(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Transferencia") {
    let context = PersistenceController.preview.container.viewContext
    let movement = try? context.fetch(Movement.fetchRequest()).first { $0.kind == .transfer }

    if let movement {
        MovementDetailView(movement: movement)
    }
}

#Preview("Gasto, oscuro y texto grande") {
    let context = PersistenceController.preview.container.viewContext
    let movement = try? context.fetch(Movement.fetchRequest()).first { $0.kind == .expense }

    if let movement {
        MovementDetailView(movement: movement)
            .preferredColorScheme(.dark)
            .dynamicTypeSize(.accessibility3)
    }
}
