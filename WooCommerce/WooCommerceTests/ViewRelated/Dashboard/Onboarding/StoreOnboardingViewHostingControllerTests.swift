import Foundation
import XCTest

@testable import WooCommerce

/// Test cases for `StoreOnboardingViewHostingController`.
///
final class StoreOnboardingViewHostingControllerTests: XCTestCase {
    func it_reloads_tasks_when_view_loads() {
        // Given
        let mockViewModel = MockStoreOnboardingViewModel()
        let sut = StoreOnboardingViewHostingController(viewModel: mockViewModel, taskTapped: { _ in }, viewAllTapped: nil, shareFeedbackAction: nil)

        // When
        sut.loadView()

        // Then
        XCTAssertTrue(mockViewModel.reloadTasksCalled)
    }

    func it_reloads_tasks_when_view_appears() {
        // Given
        let mockViewModel = MockStoreOnboardingViewModel()
        let sut = StoreOnboardingViewHostingController(viewModel: mockViewModel, taskTapped: { _ in }, viewAllTapped: nil, shareFeedbackAction: nil)

        // When
        sut.viewWillAppear(true)

        // Then
        XCTAssertTrue(mockViewModel.reloadTasksCalled)
    }
}

private class MockStoreOnboardingViewModel: StoreOnboardingViewModel {
    init() {
        super.init(isExpanded: true, siteID: 0)
    }

    var reloadTasksCalled: Bool = false

    override func reloadTasks() async {
        reloadTasksCalled = true
    }
}
