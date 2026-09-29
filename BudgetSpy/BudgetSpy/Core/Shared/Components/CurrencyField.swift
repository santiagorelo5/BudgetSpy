//
//  CurrencyField.swift
//  BudgetSpy
//

import SwiftUI

/// Amount field that starts at `$ 0,00`: each digit is appended on the right and each
/// deletion removes the last digit. Signs cannot be typed.
struct CurrencyField: View {
    private let title: String
    @Binding private var amount: Decimal
    // The typed text is kept apart from the amount so the field is always rewritten
    // with the formatted value, even when a keystroke does not change the amount.
    @State private var text: String

    init(_ title: String, amount: Binding<Decimal>) {
        self.title = title
        _amount = amount
        _text = State(initialValue: CurrencyFormatter.string(from: amount.wrappedValue))
    }

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.numberPad)
            .monospacedDigit()
            .onChange(of: text) { _, newText in
                let newAmount = CurrencyParser.amount(fromDigits: newText)
                let formatted = CurrencyFormatter.string(from: newAmount)
                if newText != formatted {
                    text = formatted
                }
                if amount != newAmount {
                    amount = newAmount
                }
            }
            .onChange(of: amount) { _, newAmount in
                let formatted = CurrencyFormatter.string(from: newAmount)
                if text != formatted {
                    text = formatted
                }
            }
    }
}

#Preview {
    @Previewable @State var amount: Decimal = 0

    Form {
        LabeledContent("Saldo disponible") {
            CurrencyField("Saldo disponible", amount: $amount)
                .multilineTextAlignment(.trailing)
        }
        LabeledContent("Valor guardado", value: "\(amount)")
    }
}
