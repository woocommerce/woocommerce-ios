import XCTest
@testable import WooCommerce

final class FilterProductListCommandTests: XCTestCase {
    private var sourceViewController: UIViewController!

    override func setUp() {
        super.setUp()
        sourceViewController = UIViewController(nibName: nil, bundle: nil)
    }

    override func tearDown() {
        sourceViewController = nil
        super.tearDown()
    }

    // MARK: Clear All CTA Visibility - initial visibility

    func testClearAllActionIsInitiallyVisibleWithOneActiveFilter() throws {
        let filters = FilterProductListCommand.Filters(stockStatus: .inStock, productStatus: nil, productType: nil)
        let command = FilterProductListCommand(sourceViewController: sourceViewController, filters: filters) { _ in }
        XCTAssertTrue(command.isClearAllActionVisible)
    }

    func testClearAllActionIsInitiallyInvisibleWithoutActiveFilters() throws {
        let filters = FilterProductListCommand.Filters(stockStatus: nil, productStatus: nil, productType: nil)
        let command = FilterProductListCommand(sourceViewController: sourceViewController, filters: filters) { _ in }
        XCTAssertFalse(command.isClearAllActionVisible)
    }

    // MARK: Clear All CTA Visibility - after tapping Clear All CTA

    func testClearAllActionIsInvisibleAfterClearingAllFilters() throws {
        // Arrange
        let filters = FilterProductListCommand.Filters(stockStatus: .inStock, productStatus: nil, productType: nil)
        let command = FilterProductListCommand(sourceViewController: sourceViewController, filters: filters) { _ in }

        // Action
        command.onClearAllActionTapped()

        // Assert
        XCTAssertFalse(command.isClearAllActionVisible)
    }

    // MARK: Filter CTA

    func testFiltersAreTheSameAfterFilterActionWithoutChanges() throws {
        // Arrange
        let filters = FilterProductListCommand.Filters(stockStatus: .inStock, productStatus: nil, productType: nil)
        var filtersOnFilterAction: FilterProductListCommand.Filters?
        let expectation = self.expectation(description: "Wait for filter action tap handling completion")
        let command = FilterProductListCommand(sourceViewController: sourceViewController, filters: filters) { filters in
            filtersOnFilterAction = filters
            expectation.fulfill()
        }

        // Action
        command.onFilterActionTapped()

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertEqual(filtersOnFilterAction, filters)
    }

    // MARK: Dismiss CTA

    func testFilterCompletionIsNotCalledAfterDismissActionWithoutChanges() throws {
        let filters = FilterProductListCommand.Filters(stockStatus: .inStock, productStatus: nil, productType: nil)
        let command = FilterProductListCommand(sourceViewController: sourceViewController, filters: filters) { filters in
            XCTFail("Should not be called on dismiss")
        }
        command.onDismissActionTapped()
    }

    // MARK: - `shouldReloadUIObservable` Observable

    func testShouldReloadUIIsEmittedAfterClearingAllFiltersWithChanges() throws {
        // Arrange
        let filters = FilterProductListCommand.Filters(stockStatus: .inStock, productStatus: nil, productType: nil)
        let command = FilterProductListCommand(sourceViewController: sourceViewController, filters: filters) { _ in }
        let expectation = self.expectation(description: "Wait for should reload UI signal")
        let observationToken = command.shouldReloadUIObservable.subscribe { _ in
            expectation.fulfill()
        }

        // Action
        command.onClearAllActionTapped()

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        observationToken.cancel()
    }

    func testShouldReloadUIIsNotEmittedAfterClearingAllFiltersWithoutChanges() throws {
        // Arrange
        let filters = FilterProductListCommand.Filters(stockStatus: nil, productStatus: nil, productType: nil)
        let command = FilterProductListCommand(sourceViewController: sourceViewController, filters: filters) { _ in }
        let observationToken = command.shouldReloadUIObservable.subscribe { _ in
            XCTFail("Should not be called since initial filters are already cleared")
        }

        // Action
        command.onClearAllActionTapped()

        observationToken.cancel()
    }
}
