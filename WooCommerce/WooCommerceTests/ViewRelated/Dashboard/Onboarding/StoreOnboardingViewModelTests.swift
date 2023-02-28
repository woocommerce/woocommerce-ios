import XCTest
@testable import WooCommerce

final class StoreOnboardingViewModelTests: XCTestCase {
    func test_numberOfTasksCompleted_returns_correct_count() {
        // Given
        let taskViewModels: [StoreOnboardingViewModel.TaskViewModel] = [
            .init(task: .addFirstProduct, isComplete: true, icon: .productImage),
            .init(task: .launchStore, isComplete: true, icon: .launchStoreImage),
            .init(task: .customizeDomains, isComplete: false, icon: .domainsImage),
            .init(task: .payments, isComplete: false, icon: .currencyImage)
        ]
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           taskViewModels: taskViewModels)

        // Then
        XCTAssertEqual(sut.numberOfTasksCompleted, 2)
    }
}
