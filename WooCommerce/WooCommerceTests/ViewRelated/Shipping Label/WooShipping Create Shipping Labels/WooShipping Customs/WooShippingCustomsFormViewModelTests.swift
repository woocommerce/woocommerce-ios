import XCTest
import Yosemite
import Combine
import YosemiteTestHelpers
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

    func test_itnValidationError_when_item_view_models_total_value_exceeds_threshold() {
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

    func test_ITNNumberValidator_when_number_is_valid_then_returns_true() {
        // Valid ITN formats
        XCTAssertTrue(ITNNumberValidator.isValid("AES X12345678901234"))
        XCTAssertTrue(ITNNumberValidator.isValid("AES 12345678901234"))
        XCTAssertTrue(ITNNumberValidator.isValid("AES ITN 12345678901234"))
        XCTAssertTrue(ITNNumberValidator.isValid("AES ITN:12345678901234"))
        XCTAssertTrue(ITNNumberValidator.isValid("aes itn:12345678901234"))
        XCTAssertTrue(ITNNumberValidator.isValid("aes x12345678901234"))

        // Valid NOEEI formats
        XCTAssertTrue(ITNNumberValidator.isValid("NOEEI 30.36"))
        XCTAssertTrue(ITNNumberValidator.isValid("NOEEI 30.37(a)"))
        XCTAssertTrue(ITNNumberValidator.isValid("NOEEI 30.37(a)(1)"))
        XCTAssertTrue(ITNNumberValidator.isValid("noeei 30.37(a)(1)"))
    }

    func test_ITNNumberValidator_when_number_is_invalid_then_returns_false() {
        // Invalid formats
        XCTAssertFalse(ITNNumberValidator.isValid("X12345678901234"))
        XCTAssertFalse(ITNNumberValidator.isValid("12345678901234"))
        XCTAssertFalse(ITNNumberValidator.isValid("AES Y12345678901234")) // Invalid prefix
        XCTAssertFalse(ITNNumberValidator.isValid("X1234567890123")) // Too short
        XCTAssertFalse(ITNNumberValidator.isValid("X123456789012345")) // Too long
        XCTAssertFalse(ITNNumberValidator.isValid("NOEEI 30.3")) // Incomplete NOEEI
        XCTAssertFalse(ITNNumberValidator.isValid("NOEEI 30.37(a)(1)(i)")) // Invalid NOEEI
        XCTAssertFalse(ITNNumberValidator.isValid("AESX12345678901234"))
        XCTAssertFalse(ITNNumberValidator.isValid("NOEEI30.36"))

        // Empty and whitespace
        XCTAssertTrue(ITNNumberValidator.isValid(""))
        XCTAssertFalse(ITNNumberValidator.isValid(" "))
    }

    func test_itnValidationError_when_totalShipmentValueExceedsThreshold_andTariffClassesDont() {
        // Given
        let storageManager = MockStorageManager()
        let originCountryCodeSubject = PassthroughSubject<String?, Never>()

        let usCountry = Country(
            code: "US",
            name: "United States",
            states: []
        )
        let ukCountry = Country(
            code: "UK",
            name: "United Kingdom",
            states: []
        )
        storageManager.insertSampleCountries(readOnlyCountries: [usCountry, ukCountry])
        let shipment = sampleShipment
        let order = Order.fake().copy(currency: "USD")

        viewModel = WooShippingCustomsFormViewModel(
            order: order,
            shipment: shipment,
            originCountryCode: originCountryCodeSubject.eraseToAnyPublisher(),
            storageManager: storageManager,
            onFormReady: { _ in }
        )

        // Set values to have a total > $2500, but each tariff class < $2500
        // Item 1 has quantity 2, Item 2 has quantity 1.
        viewModel.itemsViewModels[0].valuePerUnit = "1200" // Total: 2 * 1200 = 2400
        viewModel.itemsViewModels[1].valuePerUnit = "200"  // Total: 1 * 200 = 200
                                                           // Shipment total: 2600

        // When
        originCountryCodeSubject.send("US")
        viewModel.updateDestinationCountry(code: "UK") // A country that doesn't have special ITN rules
        viewModel.internationalTransactionNumber = "" // No ITN provided
        // Set different tariff numbers for each item
        viewModel.itemsViewModels[0].hsTariffNumber = "111111"
        viewModel.itemsViewModels[1].hsTariffNumber = "222222"
        viewModel.itemsViewModels.forEach {
            $0.description = "Test"
            $0.weightPerUnit = "1"
        }

        // Then
        // The shipment total value is 2600, which is > $2500, so an ITN should be required.
        XCTAssertEqual(viewModel.itnValidationError, .missingForTotalShipmentValue)
    }
}

private extension WooShippingCustomsFormViewModelTests {
    var sampleShipment: Shipment {
        return sampleShipment()
    }

    func sampleShipment(_ manualValuePerUnit: Double? = nil) -> Shipment {
        let item1 = ShippingLabelPackageItem(productOrVariationID: 1,
                                             orderItemID: 123,
                                             name: "Shirt",
                                             weight: 0.5,
                                             quantity: 2,
                                             value: manualValuePerUnit ?? 9.99,
                                             dimensions: ProductDimensions.fake(),
                                             attributes: [],
                                             imageURL: nil)
        let item2 = ShippingLabelPackageItem(productOrVariationID: 2,
                                             orderItemID: 55,
                                             name: "Pants",
                                             weight: 0.5,
                                             quantity: 1,
                                             value: manualValuePerUnit ?? 11,
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
