import Testing
import UIKit
@testable import WordPressUI

@MainActor
struct `UITableView Ghost Tests` {
    @Test func `call will start ghost animation before animating`() {
        let tableView = UITableView()
        tableView.register(GhostMockCell.self, forCellReuseIdentifier: "ghost")
        tableView.displayGhostContent(options: GhostOptions(reuseIdentifier: "ghost", rowsPerSection: [1]), style: .default)

        tableView.dataSource?.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))

        #expect(GhostMockCell.willStartGhostAnimationCalled)
    }

    @Test func `cell doesnt have to conform to GhostCellDelegate`() {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.displayGhostContent(options: GhostOptions(reuseIdentifier: "cell", rowsPerSection: [1]), style: .default)

        let cell = tableView.dataSource?.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))

        #expect(cell != nil)
    }

    @Test func `tableview will disable selection when animating`() {
        // Given
        let tableView = UITableView()
        tableView.register(GhostMockCell.self, forCellReuseIdentifier: "ghost")
        #expect(tableView.allowsSelection)

        // When
        tableView.displayGhostContent(options: GhostOptions(reuseIdentifier: "ghost", rowsPerSection: [1]), style: .default)

        // Then
        #expect(!tableView.allowsSelection)

        // When
        tableView.removeGhostContent()

        // Then
        #expect(tableView.allowsSelection)
    }

    @Test func `tableview will have original selection state after removing ghost content`() {
        // Given
        let tableView = UITableView()
        tableView.register(GhostMockCell.self, forCellReuseIdentifier: "ghost")
        tableView.allowsSelection = false

        // When
        tableView.displayGhostContent(options: GhostOptions(reuseIdentifier: "ghost", rowsPerSection: [1]), style: .default)

        // Then
        #expect(!tableView.allowsSelection)

        // When
        tableView.removeGhostContent()

        // Then
        #expect(!tableView.allowsSelection)
    }
}

class GhostMockCell: UITableViewCell, GhostableView {
    static var willStartGhostAnimationCalled = false

    func ghostAnimationWillStart() {
        GhostMockCell.willStartGhostAnimationCalled = true
    }
}
