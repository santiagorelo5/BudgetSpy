//
//  MovementKindTests.swift
//  BudgetSpyTests
//

import Testing
@testable import BudgetSpy

@MainActor
struct MovementKindTests {
    @Test(arguments: [
        (MovementKind.expense, "Gasto"),
        (MovementKind.income, "Ingreso"),
        (MovementKind.transfer, "Transferencia"),
    ])
    func name(kind: MovementKind, name: String) {
        #expect(kind.displayName == name)
        #expect(kind.rawValue == name)
    }

    @Test func casesAreInFormOrder() {
        #expect(MovementKind.allCases == [.expense, .income, .transfer])
    }
}
