//
//  AccountCardView.swift
//  BudgetSpy
//

import SwiftUI

struct AccountCardView: View {
    static let cornerRadius: CGFloat = 20
    /// Credit card proportion (width / height), used as the minimum height.
    static let aspectRatio: CGFloat = 1.586

    let content: AccountCardContent

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .aspectRatio(Self.aspectRatio, contentMode: .fit)

            details
                .padding(20)
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.white)
        .background(content.kind.cardGradient, in: .rect(cornerRadius: Self.cornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(content.kind.displayName)
                .font(.subheadline.weight(.semibold))
                .opacity(0.85)

            Text(content.displayedName)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .opacity(content.isNamePlaceholder ? 0.6 : 1)

            Spacer(minLength: 12)

            Text(content.maskedLastFourDigits)
                .font(.body.monospaced())

            Text(content.formattedBalance)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private extension AccountKind {
    /// Fixed colors with enough contrast for white text in light and dark mode.
    var cardGradient: LinearGradient {
        let colors: [Color] = switch self {
        case .savings:
            [Color(red: 0.04, green: 0.25, blue: 0.60), Color(red: 0.07, green: 0.44, blue: 0.80)]
        case .creditCard:
            [Color(red: 0.20, green: 0.13, blue: 0.50), Color(red: 0.45, green: 0.18, blue: 0.62)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
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
