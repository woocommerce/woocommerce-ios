import XCTest
@testable import WooCommerce
@testable import Yosemite

final class PaginatedListViewControllerStateCoordinatorTests: XCTestCase {

    func testTransitioningToSyncingState() {
        let pageNumber = 3

        let expectationForLeavingState = expectation(description: "Wait for leaving state")
        expectationForLeavingState.expectedFulfillmentCount = 1
        let onLeavingState = { (state: PaginatedListViewControllerState) in
            XCTAssertEqual(state, .results)
            expectationForLeavingState.fulfill()
        }

        let expectationForEnteringState = expectation(description: "Wait for entering state")
        expectationForEnteringState.expectedFulfillmentCount = 1
        let onEnteringState = { (state: PaginatedListViewControllerState) in
            XCTAssertEqual(state, .syncing(pageNumber: pageNumber))
            expectationForEnteringState.fulfill()
        }
        let stateCoordinator = PaginatedListViewControllerStateCoordinator(onLeavingState: onLeavingState, onEnteringState: onEnteringState)

        stateCoordinator.transitionToSyncingState(pageNumber: pageNumber)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testTransitioningToResultsUpdatedStateTwice() {
        let expectationForLeavingState = expectation(description: "Wait for leaving state")
        expectationForLeavingState.expectedFulfillmentCount = 1
        let onLeavingState = { (state: PaginatedListViewControllerState) in
            XCTAssertEqual(state, .results)
            expectationForLeavingState.fulfill()
        }

        let expectationForEnteringState = expectation(description: "Wait for entering state")
        expectationForEnteringState.expectedFulfillmentCount = 1
        let onEnteringState = { (state: PaginatedListViewControllerState) in
            XCTAssertEqual(state, .noResultsPlaceholder)
            expectationForEnteringState.fulfill()
        }
        let stateCoordinator = PaginatedListViewControllerStateCoordinator(onLeavingState: onLeavingState, onEnteringState: onEnteringState)

        // .results --> .results (no state change)
        stateCoordinator.transitionToResultsUpdatedState(hasData: true)
        // .results --> .noResultsPlaceholder
        stateCoordinator.transitionToResultsUpdatedState(hasData: false)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

}
