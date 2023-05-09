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
                XCTAssertEqual(sut.icon, .addProductImage)
            case .launchStore:
                XCTAssertEqual(sut.icon, .launchStoreImage)
            case .customizeDomains:
                XCTAssertEqual(sut.icon, .customizeDomainsImage)
            case .payments, .woocommercePayments:
                XCTAssertEqual(sut.icon, .getPaidImage)
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
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localization.StoreDetails.title)
            case .addFirstProduct:
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localization.AddFirstProduct.title)
            case .launchStore:
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localization.LaunchStore.title)
            case .customizeDomains:
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localization.CustomizeDomains.title)
            case .payments, .woocommercePayments:
                XCTAssertEqual(sut.title, StoreOnboardingTaskViewModel.Localization.Payments.title)
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
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localization.StoreDetails.subtitle)
            case .addFirstProduct:
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localization.AddFirstProduct.subtitle)
            case .launchStore:
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localization.LaunchStore.subtitle)
            case .customizeDomains:
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localization.CustomizeDomains.subtitle)
            case .payments, .woocommercePayments:
                XCTAssertEqual(sut.subtitle, StoreOnboardingTaskViewModel.Localization.Payments.subtitle)
            case .unsupported:
                XCTAssertEqual(sut.subtitle, "")
            }
        }
    }

    func test_the_badge_text_is_set_to_nil_without_badgeText_parameter() {
        for task in tasks {
            let sut = StoreOnboardingTaskViewModel(task: task)
            XCTAssertNil(sut.badgeText)
        }
    }

    func test_the_badge_text_is_set_to_badgeText_parameter() {
        for task in tasks {
            let sut = StoreOnboardingTaskViewModel(task: task, badgeText: "Tap")
            XCTAssertEqual(sut.badgeText, "Tap")
        }
    }
}
