import XCTest
import Yosemite
@testable import WooCommerce

final class ShippingLabelCustomsFormInputViewModelTests: XCTestCase {

    func test_missingContentExplanation_returns_false_when_contentType_is_not_other() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.contentsType = .documents
        viewModel.contentExplanation = ""

        // Then
        XCTAssertFalse(viewModel.missingContentExplanation)
    }

    func test_missingContentExplanation_returns_false_when_contentType_is_other_and_explanation_is_not_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.contentsType = .other
        viewModel.contentExplanation = "Test contents"

        // Then
        XCTAssertFalse(viewModel.missingContentExplanation)
    }

    func test_missingContentExplanation_returns_true_when_contentType_is_other_and_explanation_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.contentsType = .other
        viewModel.contentExplanation = ""

        // Then
        XCTAssertTrue(viewModel.missingContentExplanation)
    }

    func test_missingRestrictionComments_returns_false_when_restrictionType_is_not_other() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.restrictionType = .quarantine
        viewModel.restrictionComments = ""

        // Then
        XCTAssertFalse(viewModel.missingRestrictionComments)
    }

    func test_missingRestrictionComments_returns_false_when_restrictionType_is_other_and_comment_is_not_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.restrictionType = .other
        viewModel.restrictionComments = "Test restriction"

        // Then
        XCTAssertFalse(viewModel.missingRestrictionComments)
    }

    func test_missingRestrictionComments_returns_true_when_restrictionType_is_other_and_comment_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.restrictionType = .other
        viewModel.restrictionComments = ""

        // Then
        XCTAssertTrue(viewModel.missingRestrictionComments)
    }

    func test_missingITN_returns_false_when_ITN_validation_is_not_required() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.itn = ""

        // Then
        XCTAssertFalse(viewModel.missingITN)
    }

    func test_missingITN_returns_true_when_ITN_validation_is_required_and_itn_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: true,
                                                               currency: "$")

        // When
        viewModel.itn = ""

        // Then
        XCTAssertTrue(viewModel.missingITN)
    }

    func test_missingITN_returns_true_when_there_is_total_of_more_than_$2500_value_for_a_tariff_number_and_itn_is_empty() {
        // Given
        let item = ShippingLabelCustomsForm.Item.fake().copy(quantity: 1)
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake().copy(items: [item]),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.itn = ""
        viewModel.itemViewModels.first?.hsTariffNumber = "123456"
        viewModel.itemViewModels.first?.value = "2600"

        // Then
        XCTAssertTrue(viewModel.missingITN)
    }

    func test_contentExplanation_is_reset_when_contentType_is_not_other() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.contentsType = .other
        viewModel.contentExplanation = "Test"
        viewModel.contentsType = .documents

        // Then
        XCTAssertTrue(viewModel.contentExplanation.isEmpty)
    }

    func test_restrictionComment_is_reset_when_restrictionType_is_not_other() {
        // Given
        let viewModel = ShippingLabelCustomsFormInputViewModel(customsForm: ShippingLabelCustomsForm.fake(),
                                                               countries: [],
                                                               itnValidationRequired: false,
                                                               currency: "$")

        // When
        viewModel.restrictionType = .other
        viewModel.restrictionComments = "Test"
        viewModel.restrictionType = .sanitaryOrPhytosanitaryInspection

        // Then
        XCTAssertTrue(viewModel.restrictionComments.isEmpty)
    }
}
