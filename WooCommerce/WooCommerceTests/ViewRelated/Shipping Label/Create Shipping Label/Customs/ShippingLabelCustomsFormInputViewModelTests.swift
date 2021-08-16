import XCTest
import Yosemite
@testable import WooCommerce

final class ShippingLabelCustomsFormInputViewModelTests: XCTestCase {

    func test_hasValidContentExplanation_returns_true_when_contentType_is_not_other() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.contentsType = .documents
        viewModel.contentExplanation = ""

        // Then
        XCTAssertTrue(viewModel.hasValidContentExplanation)
    }

    func test_hasValidContentExplanation_returns_true_when_contentType_is_other_and_explanation_is_not_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.contentsType = .other
        viewModel.contentExplanation = "Test contents"

        // Then
        XCTAssertTrue(viewModel.hasValidContentExplanation)
    }

    func test_hasValidContentExplanation_returns_false_when_contentType_is_other_and_explanation_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.contentsType = .other
        viewModel.contentExplanation = ""

        // Then
        XCTAssertFalse(viewModel.hasValidContentExplanation)
    }

    func test_hasValidRestrictionComments_returns_true_when_restrictionType_is_not_other() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.restrictionType = .quarantine
        viewModel.restrictionComments = ""

        // Then
        XCTAssertTrue(viewModel.hasValidRestrictionComments)
    }

    func test_hasValidRestrictionComments_returns_true_when_restrictionType_is_other_and_comment_is_not_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.restrictionType = .other
        viewModel.restrictionComments = "Test restriction"

        // Then
        XCTAssertTrue(viewModel.hasValidRestrictionComments)
    }

    func test_hasValidRestrictionComments_returns_false_when_restrictionType_is_other_and_comment_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.restrictionType = .other
        viewModel.restrictionComments = ""

        // Then
        XCTAssertFalse(viewModel.hasValidRestrictionComments)
    }
}
