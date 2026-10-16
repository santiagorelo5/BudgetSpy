//
//  MovementRowView.swift
//  BudgetSpy
//

import SwiftUI

struct MovementRowView: View {
    let content: MovementRowContent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: content.systemImage)
                .font(.title2)
                .foregroundStyle(content.role.color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        date
                        Spacer(minLength: 8)
                        amount
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        date
                        amount
                    }
                }

                Text(content.description)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }

    private var date: some View {
        Text(content.formattedDate)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var amount: some View {
        Text(content.formattedAmount)
            .font(.body.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(content.role.color)
            .lineLimit(1)
    }
}

extension MovementRowContent.Role {
    var color: Color {
        switch self {
        case .outgoing: .red
        case .incoming: .green
        }
    }
}

#Preview("Filas") {
    let date = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 30))!

    List {
        MovementRowView(content: MovementRowContent(kind: .expense, description: "Compra de café", date: date, signedAmount: -10_000, role: .outgoing))
        MovementRowView(content: MovementRowContent(kind: .expense, description: "Mercado", date: date, signedAmount: 85_000, role: .outgoing))
        MovementRowView(content: MovementRowContent(kind: .income, description: "Pago freelance", date: date, signedAmount: 350_000, role: .incoming))
        MovementRowView(content: MovementRowContent(kind: .transfer, description: "Pago tarjeta", date: date, signedAmount: -200_000, role: .outgoing))
    }
    .listStyle(.plain)
}

#Preview("Oscuro y texto grande") {
    let date = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 30))!

    List {
        MovementRowView(content: MovementRowContent(kind: .expense, description: "Compra de café", date: date, signedAmount: -10_000, role: .outgoing))
        MovementRowView(content: MovementRowContent(kind: .transfer, description: "Ahorro mensual", date: date, signedAmount: 1_200_000, role: .incoming))
    }
    .listStyle(.plain)
    .preferredColorScheme(.dark)
    .dynamicTypeSize(.accessibility3)
}
