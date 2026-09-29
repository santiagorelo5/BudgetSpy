//
//  AddAccountCardView.swift
//  BudgetSpy
//

import SwiftUI

struct AddAccountCardView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: AccountCardView.cornerRadius)
                .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .aspectRatio(AccountCardView.aspectRatio, contentMode: .fit)
                .overlay {
                    Image(systemName: "plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .contentShape(.rect(cornerRadius: AccountCardView.cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Agregar cuenta")
    }
}

#Preview {
    AddAccountCardView {}
        .padding()
}
