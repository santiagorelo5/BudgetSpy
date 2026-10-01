//
//  MovementDetailView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

/// Read-only box with every field of a movement, as seen from the focused account,
/// so its kind, icon, sign and color always match the row.
struct MovementDetailView: View {
    let movement: Movement
    let perspective: Account

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
        MovementRowContent(movement: movement, perspective: perspective)
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

    // Seen from the destination account, as its row shows it.
    if let movement, let destination = movement.destinationAccount {
        MovementDetailView(movement: movement, perspective: destination)
    }
}

#Preview("Gasto, oscuro y texto grande") {
    let context = PersistenceController.preview.container.viewContext
    let movement = try? context.fetch(Movement.fetchRequest()).first { $0.kind == .expense }

    if let movement, let origin = movement.originAccount {
        MovementDetailView(movement: movement, perspective: origin)
            .preferredColorScheme(.dark)
            .dynamicTypeSize(.accessibility3)
    }
}
