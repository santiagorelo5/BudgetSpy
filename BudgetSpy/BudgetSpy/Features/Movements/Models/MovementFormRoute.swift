//
//  MovementFormRoute.swift
//  BudgetSpy
//

import Foundation

enum MovementFormRoute: Hashable {
    /// `originAccountID` is the focused account, used as the default origin.
    case create(originAccountID: UUID?)
    case edit(Movement)
}
