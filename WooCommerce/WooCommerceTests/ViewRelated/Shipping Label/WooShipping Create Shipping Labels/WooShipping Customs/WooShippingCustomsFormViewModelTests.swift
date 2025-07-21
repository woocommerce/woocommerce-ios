import XCTest
import Yosemite
import Combine
@testable import WooCommerce

final class WooShippingCustomsFormViewModelTests: XCTestCase {
    private var viewModel: WooShippingCustomsFormViewModel!

    override func setUp() {
        super.setUp()

        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })
    }

    override func tearDown() {
        super.tearDown()

        viewModel = nil
    }

    func test_onDismiss_calls_onCompletion_with_right_values() {
        // Given
        let shipment = sampleShipment
        var passedForm: ShippingLabelCustomsForm?
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: shipment,
                                                    onFormReady: { form in
            passedForm = form
        })

        viewModel.internationalTransactionNumber = "NOEEI 30.37(a)"
        viewModel.returnToSenderIfNotDelivered = false
        viewModel.contentType = .other
        viewModel.contentExplanation = "explanation test"
        viewModel.restrictionType = .other
        viewModel.restrictionDetails = "restriction details"

        viewModel.itemsViewModels.first?.description = "Test Item"
        viewModel.itemsViewModels.first?.valuePerUnit = "10"
        viewModel.itemsViewModels.first?.weightPerUnit = "5"
        viewModel.itemsViewModels.first?.hsTariffNumber = "123456"

        // When
        viewModel.onDismiss()

        // Then
        XCTAssertEqual(passedForm?.restrictionType, .other)
        XCTAssertEqual(passedForm?.restrictionComments, viewModel.restrictionDetails)
        XCTAssertEqual(passedForm?.contentsType, .other)
        XCTAssertEqual(passedForm?.contentExplanation, viewModel.contentExplanation)
        XCTAssertEqual(passedForm?.itn, viewModel.internationalTransactionNumber)
        XCTAssertEqual(passedForm?.nonDeliveryOption, .abandon)

        XCTAssertEqual(passedForm?.items.count, shipment.items.count)
        XCTAssertEqual(passedForm?.items.first?.productID, shipment.items.first?.productOrVariationID)
        XCTAssertEqual(passedForm?.items.first?.quantity, shipment.items.first?.quantity)
        XCTAssertEqual(passedForm?.items.first?.description, viewModel.itemsViewModels.first?.description)
        XCTAssertEqual(passedForm?.items.first?.value, Double(viewModel.itemsViewModels.first?.valuePerUnit ?? "0"))
        XCTAssertEqual(passedForm?.items.first?.weight, Double(viewModel.itemsViewModels.first?.weightPerUnit ?? "0"))
        XCTAssertEqual(passedForm?.items.first?.hsTariffNumber, viewModel.itemsViewModels.first?.hsTariffNumber)
    }

    func test_onDismiss_when_calls_onCompletion_with_invalid_hsTariffNumber_then_returns_empty() {
        // Given
        var passedForm: ShippingLabelCustomsForm?
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { form in
            passedForm = form
        })

        viewModel.itemsViewModels.first?.hsTariffNumber = "12"

        // When
        viewModel.onDismiss()

        // Then
        XCTAssertTrue(passedForm?.items.first?.hsTariffNumber.isEmpty ?? false)
    }

    func test_onDismiss_when_calls_onCompletion_with_content_and_restriction_not_other_then_returns_empty() {
        // Given
        var passedForm: ShippingLabelCustomsForm?
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { form in
            passedForm = form
        })

        viewModel.contentType = .documents
        viewModel.contentExplanation = "content explanation"

        viewModel.restrictionType = .quarantine
        viewModel.restrictionDetails = "restriction details"

        // When
        viewModel.onDismiss()

        // Then
        XCTAssertEqual(passedForm?.contentsType, .documents)
        XCTAssertEqual(passedForm?.restrictionType, .quarantine)
        XCTAssertEqual(passedForm?.contentExplanation, "")
        XCTAssertEqual(passedForm?.restrictionComments, "")
    }

    func test_onDismiss_when_calls_onCompletion_with_invalid_itn_then_returns_empty() {
        // Given
        var passedForm: ShippingLabelCustomsForm?
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { form in
            passedForm = form
        })

        viewModel.internationalTransactionNumber = "1234"

        // When
        viewModel.onDismiss()

        // Then
        XCTAssertTrue(passedForm?.itn.isEmpty ?? false)
    }

    func test_init_passes_right_currency() {
        // Given
        let order = Order.fake().copy(currency: "USD")
        viewModel = WooShippingCustomsFormViewModel(order: order,
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })

        // Then
        XCTAssertEqual(viewModel.itemsViewModels.first?.currencySymbol, "$")
    }

    func test_itnValidationError_returns_invalidFormat_for_invalid_values() {
        // Given
        let invalidValues = [
            "AES X123456789012346",
            "NOEEI 30.37(a))",
            "INVALID 123456",
            "AES X123@#4567890"
        ]

        // When & Then
        for invalidValue in invalidValues {
            viewModel.internationalTransactionNumber = invalidValue
            XCTAssertEqual(viewModel.itnValidationError, .invalidFormat)
        }
    }

    func test_itnValidationError_when_item_view_models_hsTariffNumberTotalValue_is_nil() {
        // Given
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(currency: "USD"),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })

        // When
        viewModel.itemsViewModels.forEach { item in
            item.hsTariffNumber = ""
        }

        // Then
        XCTAssertNil(viewModel.itnValidationError)

        // When
        viewModel.itemsViewModels.forEach { item in
            item.valuePerUnit = "1300"
        }

        // Then
        XCTAssertEqual(viewModel.itnValidationError, .missingForTotalShipmentValue)
    }

    func test_itnValidationError_when_item_view_models_hsTariffNumberTotalValue_is_less_than_2500() {
        // Given
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })

        // When
        viewModel.itemsViewModels.first?.hsTariffNumberTotalValue = ("123456", 1000)

        // Then
        XCTAssertNil(viewModel.itnValidationError)
    }

    func test_itnValidationError_when_item_view_models_hsTariffNumberTotalValue_is_more_than_2500() {
        // Given
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })

        // When
        viewModel.itemsViewModels[0].requiredInformationIsEntered = true
        viewModel.itemsViewModels[0].hsTariffNumberTotalValue = ("123456", 1000)
        viewModel.itemsViewModels[1].hsTariffNumberTotalValue = ("123456", 2000)
        viewModel.itemsViewModels[1].requiredInformationIsEntered = true
        viewModel.internationalTransactionNumber = ""
        viewModel.updateDestinationCountry(code: "CA") // ITN is not required for Canada

        // Then
        XCTAssertTrue(viewModel.requiredInformationIsEntered)
        XCTAssertNil(viewModel.itnValidationError)

        // When
        viewModel.updateDestinationCountry(code: "UK")

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
        XCTAssertEqual(viewModel.itnValidationError, .missingForTariffClass)
    }

    func test_itnValidationError_when_destination_country_requires_ITN() {
        // Given
        let requiredDestinations = ["IR", "SY", "KP", "CU", "SD"]
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })
        viewModel.itemsViewModels.forEach { item in
            item.hsTariffNumber = ""
            item.valuePerUnit = "1000"
        }

        // When
        viewModel.updateDestinationCountry(code: "UK")

        // Then
        XCTAssertNil(viewModel.itnValidationError)

        // When
        for destination in requiredDestinations {
            viewModel.updateDestinationCountry(code: destination)

            // Then
            XCTAssertEqual(viewModel.itnValidationError, .missingForRequiredDestination)
        }
    }

    func test_requiredInformationIsEntered_when_itn_is_required_but_invalid_then_returns_false() {
        // Given
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })

        // When
        viewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.internationalTransactionNumber = "1234"

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
    }

    func test_requiredInformationIsEntered_when_itn_is_required_and_valid_then_returns_true() {
        // Given
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })

        // When
        viewModel.internationalTransactionNumber = "NOEEI 30.37(a)"
        viewModel.itemsViewModels.forEach { $0.requiredInformationIsEntered = true }

        // Then
        XCTAssertTrue(viewModel.requiredInformationIsEntered)
    }

    func test_requiredInformationIsEntered_when_content_type_is_other_but_details_are_empty_then_returns_false() {
        // Given
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })

        // When
        viewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.itemsViewModels[1].requiredInformationIsEntered = true
        viewModel.contentType = .other
        viewModel.contentExplanation = ""

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
    }

    func test_requiredInformationIsEntered_when_restriction_type_is_other_but_details_are_empty_then_returns_false() {
        // Given
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })

        // When
        viewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.itemsViewModels[1].requiredInformationIsEntered = true
        viewModel.restrictionType = .other
        viewModel.restrictionDetails = ""

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
    }

    func test_requiredInformationIsEntered_when_required_data_is_entered_then_returns_true() {
        // Given
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: sampleShipment,
                                                    onFormReady: { _ in })

        // When
        viewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.itemsViewModels[1].requiredInformationIsEntered = true
        viewModel.restrictionType = .other
        viewModel.restrictionDetails = "test"
        viewModel.contentType = .other
        viewModel.contentExplanation = "test"
        viewModel.internationalTransactionNumber = "NOEEI 30.37(a)"

        // Then
        XCTAssertTrue(viewModel.requiredInformationIsEntered)
    }

    func test_init_when_shipment_has_items_then_prefills_item_details() {
        // Given
        let shipment = sampleShipment
        let firstItem = shipment.items.first

        // When
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(),
                                                    shipment: shipment,
                                                    onFormReady: { _ in })
        let firstItemViewModel = viewModel.itemsViewModels.first

        // Then
        XCTAssertEqual(firstItemViewModel?.description, firstItem?.name)
        XCTAssertEqual(firstItemViewModel?.valuePerUnit, String(firstItem?.value ?? 0))
        XCTAssertEqual(firstItemViewModel?.weightPerUnit, String(firstItem?.weight ?? 0))
    }

    func test_requiredInformationIsEntered_when_weight_is_zero_then_returns_false() {
        // Given
        let storageManager = MockStorageManager()
        let originCountryCodeSubject = PassthroughSubject<String?, Never>()

        let country = Country(
            code: "US",
            name: "United States",
            states: []
        )
        storageManager.insertSampleCountries(readOnlyCountries: [country])

        let itemWithZeroWeight = ShippingLabelPackageItem(
            productOrVariationID: 1,
            orderItemID: 123,
            name: "Shirt",
            weight: 0,
            quantity: 1,
            value: 10,
            dimensions: .fake(),
            attributes: [],
            imageURL: nil
        )

        let shipment = Shipment(
            contents: [
                CollapsibleShipmentItemCardViewModel(
                    item: itemWithZeroWeight,
                    currency: "USD"
                )
            ],
            currency: "USD",
            currencySettings: ServiceLocator.currencySettings,
            shippingSettingsService: ServiceLocator.shippingSettingsService
        )

        viewModel = WooShippingCustomsFormViewModel(
            order: .fake(),
            shipment: shipment,
            originCountryCode: originCountryCodeSubject.eraseToAnyPublisher(),
            storageManager: storageManager,
            onFormReady: { _ in }
        )

        let itemViewModel = viewModel.itemsViewModels[0]
        itemViewModel.description = "Test Description"
        itemViewModel.valuePerUnit = "10.0"

        // When
        originCountryCodeSubject.send("US")

        // Then
        XCTAssertFalse(
            viewModel.requiredInformationIsEntered,
            "requiredInformationIsEntered should be false when an item's weight is zero"
        )
        XCTAssertTrue(itemViewModel.weightPerUnit.isEmpty)
        XCTAssertFalse(itemViewModel.isValidWeight)
        XCTAssertFalse(itemViewModel.requiredInformationIsEntered)
    }
}

private extension WooShippingCustomsFormViewModelTests {
    var sampleShipment: Shipment {
        let item1 = ShippingLabelPackageItem(productOrVariationID: 1,
                                             orderItemID: 123,
                                             name: "Shirt",
                                             weight: 0.5,
                                             quantity: 2,
                                             value: 9.99,
                                             dimensions: ProductDimensions.fake(),
                                             attributes: [],
                                             imageURL: nil)
        let item2 = ShippingLabelPackageItem(productOrVariationID: 2,
                                             orderItemID: 55,
                                             name: "Pants",
                                             weight: 0.5,
                                             quantity: 1,
                                             value: 11,
                                             dimensions: ProductDimensions.fake(),
                                             attributes: [],
                                             imageURL: nil)
        return Shipment(contents: [CollapsibleShipmentItemCardViewModel(item: item1, currency: "USD"),
                                   CollapsibleShipmentItemCardViewModel(item: item2, currency: "USD")],
                        currency: "USD",
                        currencySettings: ServiceLocator.currencySettings,
                        shippingSettingsService: ServiceLocator.shippingSettingsService)
    }
}
