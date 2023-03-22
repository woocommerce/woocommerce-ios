import XCTest
import Yosemite
@testable import WooCommerce

final class StoreOnboardingTaskViewModelTests: XCTestCase {
    private let tasks: [StoreOnboardingTask] = [
        .init(isComplete: true, type: .addFirstProduct),
        .init(isComplete: true, type: .launchStore),
        .init(isComplete: true, type: .customizeDomains),
        .init(isComplete: true, type: .payments)
    ]

    func test_it_returns_isComplete_based_on_the_passed_in_task() {
        // Given
        let task: StoreOnboardingTask = .init(isComplete: true, type: .addFirstProduct)

        // When
        let sut = StoreOnboardingTaskViewModel(task: task)

        // Then
        XCTAssertEqual(true, sut.isComplete)
    }

    func test_it_returns_the_passed_in_task() {
        // Given
        let task: StoreOnboardingTask = .init(isComplete: true, type: .addFirstProduct)

        // When
        let sut = StoreOnboardingTaskViewModel(task: task)

        // Then
        XCTAssertEqual(task, sut.task)
    }

    func test_the_icon_is_correct_for_different_type_of_tasks() {
        for task in tasks {
            let sut = StoreOnboardingTaskViewModel(task: task)
            switch task.type {
            case .storeDetails:
                XCTAssertEqual(sut.icon, .storeDetailsImage)
            case .addFirstProduct:
                XCTAssertEqual(sut.icon, .productImage)
            case .launchStore:
                XCTAssertEqual(sut.icon, .launchStoreImage)
            case .customizeDomains:
                XCTAssertEqual(sut.icon, .domainsImage)
            case .payments, .woocommercePayments:
                XCTAssertEqual(sut.icon, .currencyImage)
            case .unsupported:
                XCTAssertEqual(sut.icon, .checkCircleImage)
            }
        }
    }

    func test_the_title_is_correct_for_different_type_of_tasks() {
        for task in tasks {
            let sut = StoreOnboardingTaskViewModel(task: task)
            switch task.type {
            case .storeDetails:
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localication.StoreDetails.title)
            case .addFirstProduct:
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localication.AddFirstProduct.title)
            case .launchStore:
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localication.LaunchStore.title)
            case .customizeDomains:
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localication.CustomizeDomains.title)
            case .payments, .woocommercePayments:
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localication.Payments.title)
            case .unsupported:
                XCTAssertEqual(sut.title, "")
            }
        }
    }

    func test_the_subtitle_is_correct_for_different_type_of_tasks() {
        for task in tasks {
            let sut = StoreOnboardingTaskViewModel(task: task)
            switch task.type {
            case .storeDetails:
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localication.StoreDetails.subtitle)
            case .addFirstProduct:
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localication.AddFirstProduct.subtitle)
            case .launchStore:
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localication.LaunchStore.subtitle)
            case .customizeDomains:
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localication.CustomizeDomains.subtitle)
            case .payments, .woocommercePayments:
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localication.Payments.subtitle)
            case .unsupported:
                XCTAssertEqual(sut.subtitle, "")
            }
        }
    }
}
