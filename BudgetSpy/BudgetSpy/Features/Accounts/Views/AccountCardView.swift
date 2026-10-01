//
//  AccountCardView.swift
//  BudgetSpy
//

import SwiftUI

struct AccountCardView: View {
    static let cornerRadius: CGFloat = 20
    /// Credit card proportion (width / height). The card always keeps it exactly.
    static let aspectRatio: CGFloat = 1.586

    let content: AccountCardContent

    var body: some View {
        details
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            // The text shrinks to fit instead of stretching the card; VoiceOver reads the full label.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .foregroundStyle(.white)
        .background {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(content.kind.cardGradient)
                .overlay(Self.rightShading, in: .rect(cornerRadius: Self.cornerRadius))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }

    /// Darkens the right edge so the card looks lit from the left.
    private static let rightShading = LinearGradient(
        colors: [.clear, .black.opacity(0.35)],
        startPoint: UnitPoint(x: 0.45, y: 0.5),
        endPoint: .trailing
    )

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(content.kind.displayName)
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.85)

                Spacer()

                Image(systemName: content.kind.cardSymbolName)
                    .font(.title3)
                    .opacity(0.9)
                    .accessibilityHidden(true)
            }

            Text(content.displayedName)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .opacity(content.isNamePlaceholder ? 0.6 : 1)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Text(content.maskedLastFourDigits)
                    .font(.body.monospaced())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(systemName: "wave.3.right")
                    .font(.subheadline)
                    .opacity(0.8)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(content.kind.balanceTitle)
                    .font(.caption)
                    .lineLimit(1)
                    .opacity(0.85)

                Text(content.formattedBalance)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private extension AccountKind {
    /// Fixed dark colors with enough contrast for white text in light and dark mode.
    var cardGradient: LinearGradient {
        let colors: [Color] = switch self {
        case .savings:
            [Color(red: 0.12, green: 0.23, blue: 0.54), Color(red: 0.06, green: 0.12, blue: 0.36)]
        case .creditCard:
            [Color(red: 0.29, green: 0.29, blue: 0.31), Color(red: 0.16, green: 0.16, blue: 0.18)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .trailing)
    }

    var cardSymbolName: String {
        switch self {
        case .savings: "banknote"
        case .creditCard: "creditcard"
        }
    }
}

#Preview("Claro") {
    AccountCardPreviews()
}

#Preview("Oscuro") {
    AccountCardPreviews()
        .preferredColorScheme(.dark)
}

private struct AccountCardPreviews: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AccountCardView(content: AccountCardContent(
                    kind: .savings, name: "Nómina Bancolombia", lastFourDigits: "4821", balance: 1_250_000
                ))
                AccountCardView(content: AccountCardContent(
                    kind: .creditCard, name: "Visa", lastFourDigits: "1234", balance: 1_200_000
                ))
                AccountCardView(content: AccountCardContent(draft: AccountDraft()))
            }
            .padding()
        }
    }
}
