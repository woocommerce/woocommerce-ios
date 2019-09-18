import XCTest
@testable import WooCommerce
@testable import Yosemite

class ProductSearchControllerStateCoordinatorTests: XCTestCase {

    func testTransitioningToResultsUpdatedState() {
        let hasExistingData = true

        let expectationForLeavingState = expectation(description: "Wait for leaving state")
        expectationForLeavingState.expectedFulfillmentCount = 1
        let onLeavingState = { (state: ProductSearchViewControllerState) in
            XCTAssertEqual(state, .noResultsPlaceholder)
            expectationForLeavingState.fulfill()
        }

        let expectationForEnteringState = expectation(description: "Wait for entering state")
        expectationForEnteringState.expectedFulfillmentCount = 1
        let onEnteringState = { (state: ProductSearchViewControllerState) in
            XCTAssertEqual(state, .results)
            expectationForEnteringState.fulfill()
        }
        let stateCoordinator = ProductSearchViewControllerStateCoordinator(onLeavingState: onLeavingState, onEnteringState: onEnteringState)

        stateCoordinator.transitionToResultsUpdatedState(hasData: hasExistingData)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testTransitioningToSyncingState() {
        let expectationForLeavingState = expectation(description: "Wait for leaving state")
        expectationForLeavingState.expectedFulfillmentCount = 1
        let onLeavingState = { (state: ProductSearchViewControllerState) in
            XCTAssertEqual(state, .noResultsPlaceholder)
            expectationForLeavingState.fulfill()
        }

        let expectationForEnteringState = expectation(description: "Wait for entering state")
        expectationForEnteringState.expectedFulfillmentCount = 1
        let onEnteringState = { (state: ProductSearchViewControllerState) in
            XCTAssertEqual(state, .syncing)
            expectationForEnteringState.fulfill()
        }
        let stateCoordinator = ProductSearchViewControllerStateCoordinator(onLeavingState: onLeavingState, onEnteringState: onEnteringState)

        stateCoordinator.transitionToSyncingState()
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testTransitioningToResultsUpdatedStateTwice() {
        let expectationForLeavingState = expectation(description: "Wait for leaving state")
        expectationForLeavingState.expectedFulfillmentCount = 1
        let onLeavingState = { (state: ProductSearchViewControllerState) in
            XCTAssertEqual(state, .noResultsPlaceholder)
            expectationForLeavingState.fulfill()
        }

        let expectationForEnteringState = expectation(description: "Wait for entering state")
        expectationForEnteringState.expectedFulfillmentCount = 1
        let onEnteringState = { (state: ProductSearchViewControllerState) in
            XCTAssertEqual(state, .results)
            expectationForEnteringState.fulfill()
        }
        let stateCoordinator = ProductSearchViewControllerStateCoordinator(onLeavingState: onLeavingState, onEnteringState: onEnteringState)

        // .noResultsPlaceholder --> .noResultsPlaceholder (no state change)
        stateCoordinator.transitionToResultsUpdatedState(hasData: false)
        // .noResultsPlaceholder --> .results
        stateCoordinator.transitionToResultsUpdatedState(hasData: true)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

}
