//
//  AppTab.swift
//  BudgetSpy
//

enum AppTab: Hashable {
    case home
    /// Action that opens the movement form; it is never kept as the selected tab.
    case newMovement
    case settings
}
