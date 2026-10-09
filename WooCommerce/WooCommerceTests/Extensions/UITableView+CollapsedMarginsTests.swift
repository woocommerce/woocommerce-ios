import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct UITableView_CollapsedMarginsTests {

    private let systemMinimum = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

    @Test
    func test_restoreCollapsedLayoutMarginsIfNeeded_when_margins_are_symmetric_then_leaves_them_unchanged() {
        // Given
        let tableView = UITableView()
        tableView.layoutMargins = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)

        // When
        tableView.restoreCollapsedLayoutMarginsIfNeeded(systemMinimumLayoutMargins: systemMinimum)

        // Then
        #expect(tableView.layoutMargins == UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
    }

    @Test
    func test_restoreCollapsedLayoutMarginsIfNeeded_when_trailing_collapsed_then_sets_both_sides_to_the_leading_one() {
        // Given
        let tableView = UITableView()
        tableView.layoutMargins = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 0)

        // When
        tableView.restoreCollapsedLayoutMarginsIfNeeded(systemMinimumLayoutMargins: systemMinimum)

        // Then
        #expect(tableView.layoutMargins == UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
    }

    @Test
    func test_restoreCollapsedLayoutMarginsIfNeeded_when_leading_collapsed_then_sets_both_sides_to_the_trailing_one() {
        // Given
        let tableView = UITableView()
        tableView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 20)

        // When
        tableView.restoreCollapsedLayoutMarginsIfNeeded(systemMinimumLayoutMargins: systemMinimum)

        // Then
        #expect(tableView.layoutMargins == UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
    }

    @Test
    func test_restoreCollapsedLayoutMarginsIfNeeded_when_both_sides_collapsed_then_falls_back_to_system_minimum() {
        // Given
        let tableView = UITableView()
        tableView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        // When
        tableView.restoreCollapsedLayoutMarginsIfNeeded(systemMinimumLayoutMargins: systemMinimum)

        // Then
        #expect(tableView.layoutMargins == UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
    }

    @Test
    func test_restoreCollapsedLayoutMarginsIfNeeded_when_both_sides_and_fallback_are_zero_then_leaves_them_unchanged() {
        // Given
        let tableView = UITableView()
        tableView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        // When
        tableView.restoreCollapsedLayoutMarginsIfNeeded(systemMinimumLayoutMargins: .zero)

        // Then
        #expect(tableView.layoutMargins == UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
    }
}
