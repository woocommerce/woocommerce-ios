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

    func test_tasksForDisplay_returns_only_incomplete_tasks() {
        // Given
        let taskViewModels: [StoreOnboardingViewModel.TaskViewModel] = [
            .init(task: .addFirstProduct, isComplete: true, icon: .productImage),
            .init(task: .launchStore, isComplete: false, icon: .launchStoreImage),
            .init(task: .customizeDomains, isComplete: true, icon: .domainsImage),
            .init(task: .payments, isComplete: false, icon: .currencyImage)
        ]
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           taskViewModels: taskViewModels)

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 2)
    }

    func test_tasksForDisplay_returns_first_3_incomplete_tasks_when_isExpanded_is_false() {
        // Given
        let taskViewModels: [StoreOnboardingViewModel.TaskViewModel] = [
            .init(task: .addFirstProduct, isComplete: false, icon: .productImage),
            .init(task: .launchStore, isComplete: false, icon: .launchStoreImage),
            .init(task: .customizeDomains, isComplete: false, icon: .domainsImage),
            .init(task: .payments, isComplete: false, icon: .currencyImage)
        ]
        let sut = StoreOnboardingViewModel(isExpanded: false,
                                           taskViewModels: taskViewModels)

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 3)
    }

    func test_tasksForDisplay_returns_all_incomplete_tasks_when_isExpanded_is_true() {
        // Given
        let taskViewModels: [StoreOnboardingViewModel.TaskViewModel] = [
            .init(task: .addFirstProduct, isComplete: false, icon: .productImage),
            .init(task: .launchStore, isComplete: false, icon: .launchStoreImage),
            .init(task: .customizeDomains, isComplete: false, icon: .domainsImage),
            .init(task: .payments, isComplete: false, icon: .currencyImage)
        ]
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           taskViewModels: taskViewModels)

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 4)
    }
}
