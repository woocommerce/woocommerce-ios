import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductTypeBottomSheetListSelectorCommandTests: XCTestCase {

    func test_data_contains_subscription_types_if_eligible_for_creation_form() {
        // Given
        let subscriptionEligibilityChecker = MockWooSubscriptionProductsEligibilityChecker(isEligible: true)

        // When
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .creationForm,
            subscriptionProductsEligibilityChecker: subscriptionEligibilityChecker
        ) { _ in }

        // Then
        let expectedTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .subscription,
            .variable,
            .variableSubscription,
            .grouped,
            .affiliate
        ]
        assertEqual(expectedTypes, command.data)
    }

    func test_data_does_not_contain_subscription_types_if_ineligible_for_creation_form() {
        // Given
        let subscriptionEligibilityChecker = MockWooSubscriptionProductsEligibilityChecker(isEligible: false)

        // When
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .creationForm,
            subscriptionProductsEligibilityChecker: subscriptionEligibilityChecker
        ) { _ in }

        // Then
        let expectedTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .variable,
            .grouped,
            .affiliate
        ]
        assertEqual(expectedTypes, command.data)
    }

    func test_data_contains_subscription_types_if_eligible_for_edit_form() {
        // Given
        let subscriptionEligibilityChecker = MockWooSubscriptionProductsEligibilityChecker(isEligible: true)

        // When
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .editForm(selected: .variable),
            subscriptionProductsEligibilityChecker: subscriptionEligibilityChecker
        ) { _ in }

        // Then
        let expectedTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .subscription,
            .variableSubscription,
            .grouped,
            .affiliate
        ]
        assertEqual(expectedTypes, command.data)
    }

    func test_data_does_not_contain_subscription_types_if_ineligible_for_edit_form() {
        // Given
        let subscriptionEligibilityChecker = MockWooSubscriptionProductsEligibilityChecker(isEligible: false)

        // When
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .editForm(selected: .variable),
            subscriptionProductsEligibilityChecker: subscriptionEligibilityChecker
        ) { _ in }

        // Then
        let expectedTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .grouped,
            .affiliate
        ]
        assertEqual(expectedTypes, command.data)
    }

    func test_callback_is_called_on_selection() {
        // Arrange
        let subscriptionEligibilityChecker = MockWooSubscriptionProductsEligibilityChecker(isEligible: true)
        var selectedActions = [BottomSheetProductType]()
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .editForm(selected: .simple(isVirtual: false)),
            subscriptionProductsEligibilityChecker: subscriptionEligibilityChecker
        ) { (selected) in
            selectedActions.append(selected)
        }

        // Action
        command.handleSelectedChange(selected: .simple(isVirtual: true))
        command.handleSelectedChange(selected: .grouped)
        command.handleSelectedChange(selected: .variable)
        command.handleSelectedChange(selected: .affiliate)
        command.handleSelectedChange(selected: .subscription)
        command.handleSelectedChange(selected: .variableSubscription)

        // Assert
        let expectedActions: [BottomSheetProductType] = [
            .simple(isVirtual: true),
            .grouped,
            .variable,
            .affiliate,
            .subscription,
            .variableSubscription
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }
}
