//
//  AccountValidator.swift
//  BudgetSpy
//

import Foundation

/// Business rules of an account; the only source of the form's validation errors.
struct AccountValidator {
    static let maximumNameLength = 20
    static let lastFourDigitsLength = 4

    func errors(for draft: AccountDraft) -> [AccountField: AccountValidationError] {
        var errors: [AccountField: AccountValidationError] = [:]
        errors[.name] = nameError(for: draft.name)
        errors[.lastFourDigits] = lastFourDigitsError(for: draft.lastFourDigits)
        if draft.balance < 0 {
            errors[.balance] = .negativeBalance
        }
        if draft.kind.requiresCreditLimit {
            errors[.creditLimit] = creditLimitError(limit: draft.creditLimit, debt: draft.balance)
        }
        return errors
    }

    private func nameError(for name: String) -> AccountValidationError? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyName
        }
        if name.count > Self.maximumNameLength {
            return .nameTooLong
        }
        return nil
    }

    private func lastFourDigitsError(for digits: String) -> AccountValidationError? {
        let isValid = digits.count == Self.lastFourDigitsLength && digits.allSatisfy(\.isASCIIDigit)
        return isValid ? nil : .incompleteLastFourDigits
    }

    private func creditLimitError(limit: Decimal, debt: Decimal) -> AccountValidationError? {
        if limit <= 0 {
            return .missingCreditLimit
        }
        if limit < debt {
            return .creditLimitBelowDebt
        }
        return nil
    }
}
