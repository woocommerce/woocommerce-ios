import Foundation
import XCTest

@testable import WooCommerce

/// Test cases for `StoreOnboardingViewHostingController`.
///
final class StoreOnboardingViewHostingControllerTests: XCTestCase {
    func test_it_reloads_tasks_when_view_loads() {
        // Given
        let mockViewModel = MockStoreOnboardingViewModel()
        let sut = StoreOnboardingViewHostingController(viewModel: mockViewModel, navigationController: .init(), site: .fake(), shareFeedbackAction: nil)

        // When
        sut.viewDidLoad()

        // Then
        waitUntil {
            mockViewModel.reloadTasksCalled
        }
    }

    func test_it_reloads_tasks_when_view_appears() {
        // Given
        let mockViewModel = MockStoreOnboardingViewModel()
        let sut = StoreOnboardingViewHostingController(viewModel: mockViewModel, navigationController: .init(), site: .fake(), shareFeedbackAction: nil)

        // When
        sut.viewWillAppear(true)

        // Then
        waitUntil {
            mockViewModel.reloadTasksCalled
        }
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
