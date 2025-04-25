import XCTest
import Combine
@testable import WooCommerce
@testable import Networking
import WooFoundation
import Yosemite

final class WooShippingShipmentDetailsViewModelTests: XCTestCase {

    func test_inits_with_expected_values_for_shipping_label_creation() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertNil(viewModel.totalCost)
        XCTAssertFalse(viewModel.canViewLabel)
    }

    func test_inits_with_expected_values_for_viewing_purchased_label() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: .fake().copy(rate: 22.0),
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertNotNil(viewModel.postPurchase)
        XCTAssertNotNil(viewModel.totalCost)
        XCTAssertTrue(viewModel.canViewLabel)
        XCTAssertEqual(viewModel.shippingRates.count, 1)
    }

    func test_isPurchaseButtonEnabled_true_when_required_fields_are_set() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())
        XCTAssertFalse(viewModel.isPurchaseButtonEnabled)

        // When
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())
        viewModel.selectPackage(samplePackageData())

        // Then
        XCTAssertTrue(viewModel.isPurchaseButtonEnabled)
    }

    func test_selecting_standard_shipping_rate_sets_expected_shippingRates() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // When
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 1)
        XCTAssertEqual(viewModel.shippingRates.first?.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(viewModel.shippingRates.first?.amount, "$40.06")
    }

    func test_selecting_signature_shipping_rate_sets_expected_shippingRates() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // When
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate(with: .signatureRequired))

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 2)
        XCTAssertEqual(viewModel.shippingRates[0].title, "USPS - Parcel Select Mail (base fee)")
        XCTAssertEqual(viewModel.shippingRates[0].amount, "$40.06")
        XCTAssertEqual(viewModel.shippingRates[1].title, "Signature Required")
        XCTAssertEqual(viewModel.shippingRates[1].amount, "$2.70")
    }

    func test_selecting_adult_signature_shipping_rate_sets_expected_shippingRates() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // When
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate(with: .adultSignatureRequired))

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 2)
        XCTAssertEqual(viewModel.shippingRates[0].title, "USPS - Parcel Select Mail (base fee)")
        XCTAssertEqual(viewModel.shippingRates[0].amount, "$40.06")
        XCTAssertEqual(viewModel.shippingRates[1].title, "Adult Signature Required")
        XCTAssertEqual(viewModel.shippingRates[1].amount, "$6.90")
    }

    @MainActor
    func test_purchaseLabel_sets_postPurchase_with_purchased_shipping_label() async throws {
        // Given
        let expectedShippingLabel = ShippingLabel.fake().copy(carrierID: "usps", trackingNumber: "1234567890")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
                                                            stores: stores)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, completion):
                completion(.success(expectedShippingLabel))
            case .loadPackages, .loadOriginAddresses, .verifyDestinationAddress, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        viewModel.selectPackage(samplePackageData())
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())
        try await viewModel.purchaseLabel()

        // Then
        XCTAssertNotNil(viewModel.postPurchase)
        XCTAssertEqual(viewModel.postPurchase?.pickupURL, WooShippingCarrier(rawValue: expectedShippingLabel.carrierID)?.pickupURL)
        XCTAssertEqual(viewModel.postPurchase?.trackingURL, ShippingLabelTrackingURLGenerator.url(for: expectedShippingLabel))
    }

    @MainActor
    func test_purchaseLabel_sets_hazmat_category_correctly() async throws {
        // Given
        var encodedHazmat: [String: Any]?
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
                                                            stores: stores)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .purchaseShippingLabel(_, _, _, _, package, _, _, _, completion):
                encodedHazmat = package.encodedHazmat()
                completion(.success(ShippingLabel.fake()))
            case let .loadLabelRates(_, _, _, _, packages, completion):
                completion(packages, .success([]))
            case .loadPackages, .loadOriginAddresses, .verifyDestinationAddress, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        viewModel.hazmatCategory = .class3
        viewModel.selectPackage(samplePackageData())
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())
        try await viewModel.purchaseLabel()

        // Then
        let shipmentDetails = encodedHazmat?[viewModel.shipment.id] as? [String: Any]
        XCTAssertEqual(shipmentDetails?["isHazmat"] as? Bool, true)
        XCTAssertEqual(shipmentDetails?["category"] as? String, ShippingLabelHazmatCategory.class3.rawValue)
    }

    func test_selectPackage_sets_selectedPackage_with_package_data() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // When
        viewModel.selectPackage(samplePackageData())

        // Then
        XCTAssertNotNil(viewModel.selectedPackage)
        XCTAssertEqual(viewModel.selectedPackage?.id, samplePackageData().id)
    }

    func test_selectPackage_sets_shipmentWeight_with_items_and_package_weight() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // When
        viewModel.selectPackage(samplePackageData())

        // Then
        XCTAssertEqual(viewModel.shipmentWeight, "1.25")
    }

    func test_changing_shipmentWeight_loads_new_label_rates_with_updated_weight() {
        // Given
        let expectedWeight = 2.5
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
                                                            stores: stores,
                                                            debounceDuration: 0)


        // When
        viewModel.selectPackage(samplePackageData())
        let packageWeightForLabelRates = waitFor { promise in
            stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
                switch action {
                case let .loadLabelRates(_, _, _, _, packages, _):
                    promise(packages.first?.weight)
                case .loadOriginAddresses(_, let completion):
                    completion(.success([]))
                case .loadConfig:
                    break
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            viewModel.shipmentWeight = expectedWeight.description
        }

        // Then
        XCTAssertEqual(packageWeightForLabelRates, expectedWeight)
    }

    func test_totalCost_has_expected_value_when_shipping_rate_is_set() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // When
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())

        // Then
        XCTAssertEqual(viewModel.totalCost, "$40.06")
    }

    func test_shouldShowCustomsForm_when_origin_and_destination_in_US_then_returns_false() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertFalse(viewModel.shouldShowCustomsForm)
    }

    func test_shouldShowCustomsForm_when_origin_address_is_US_military_then_returns_true() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "AA"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertTrue(viewModel.shouldShowCustomsForm)
    }

    func test_shouldShowCustomsForm_when_destination_address_is_US_military_then_returns_true() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "AA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertTrue(viewModel.shouldShowCustomsForm)
    }

    func test_shouldShowCustomsForm_when_destination_address_is_not_in_US_then_returns_true() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "GB", state: "LD"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertTrue(viewModel.shouldShowCustomsForm)
    }

    func test_shouldShowCustomsForm_when_shipping_label_is_purchased_then_returns_false() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "GB", state: "LD"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: ShippingLabel.fake(),
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertFalse(viewModel.shouldShowCustomsForm)
    }

    func test_itnMissingNoticeLabel_when_customs_form_is_not_required() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertNil(viewModel.itnMissingNoticeLabel)
    }

    func test_itnMissingNoticeLabel_when_customs_form_is_required() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "GB", state: "LD"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertNil(viewModel.itnMissingNoticeLabel)

        // When: destination country is updated to require ITN
        viewModel.customsFormViewModel.updateDestinationCountry(code: "IR")

        // Then
        XCTAssertNotNil(viewModel.itnMissingNoticeLabel)
    }

    func test_customsInformationIsCompleted_when_custom_form_is_filled() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "GB", state: "LD"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())
        viewModel.customsFormViewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.customsFormViewModel.contentType = .documents
        viewModel.customsFormViewModel.restrictionType = .quarantine

        // Then
        XCTAssertTrue(viewModel.customsInformationIsCompleted)

        // When: destination country requires ITN
        viewModel.customsFormViewModel.updateDestinationCountry(code: "IR")

        // Then
        XCTAssertFalse(viewModel.customsInformationIsCompleted)
    }
}

private extension WooShippingShipmentDetailsViewModelTests {
    var sampleShipment: Shipment {
        let item = ShippingLabelPackageItem(productOrVariationID: 1,
                                            orderItemID: 123,
                                            name: "Shirt",
                                            weight: 0.5,
                                            quantity: 2,
                                            value: 9.99,
                                            dimensions: ProductDimensions.fake(),
                                            attributes: [],
                                            imageURL: nil)
        return Shipment(contents: [CollapsibleShipmentItemCardViewModel(item: item, currency: "GBP")],
                        currency: "GBP",
                        currencySettings: ServiceLocator.currencySettings,
                        shippingSettingsService: ServiceLocator.shippingSettingsService)
    }

    func samplePackageData() -> WooShippingPackageDataRepresentable {
        WooShippingPackageData(id: "small_flat_box",
                               name: "Small Flat Rate Box",
                               length: "21.91",
                               width: "13.65",
                               height: "4.13",
                               weight: ".25",
                               source: .predefined(sourceTitle: "usps", sourceID: "usps"),
                               packageType: "box")
    }

    func sampleOriginAddress(country: String, state: String) -> WooShippingAddress {
        WooShippingAddress(company: "HEADQUARTERS",
                           name: "John Doe",
                           phone: "",
                           country: country,
                           state: state,
                           address1: "15 ALGONKIN ST",
                           address2: "STE 100",
                           city: "TICONDEROGA",
                           postcode: "12883-1487"
        )
    }

    func sampleDestinationAddress(country: String, state: String) -> WooShippingAddress {
        WooShippingAddress(company: "",
                           name: "",
                           phone: "",
                           country: country,
                           state: state,
                           address1: "1 Main Street",
                           address2: "",
                           city: "San Francisco",
                           postcode: "12345")
    }

    func sampleSelectedRate(with signatureRequirement: WooShippingServiceCardViewModel.SignatureRequirement = .none) -> WooShippingSelectedRate {
        WooShippingSelectedRate(rate: ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                                               insurance: "100",
                                                               retailRate: 40.06,
                                                               rate: 40.06,
                                                               rateID: "rate_a8a29d5f34984722942f466c30ea27eh",
                                                               serviceID: "",
                                                               carrierID: "usps",
                                                               shipmentID: "",
                                                               hasTracking: true,
                                                               isSelected: false,
                                                               isPickupFree: true,
                                                               deliveryDays: 2,
                                                               deliveryDateGuaranteed: false),
                                signatureRate: signatureRequirement == .signatureRequired ?
                                    ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                                             insurance: "100",
                                                             retailRate: 42.76,
                                                             rate: 42.76,
                                                             rateID: "rate_a8a29d5f34984722942f466c30ea27ei",
                                                             serviceID: "",
                                                             carrierID: "usps",
                                                             shipmentID: "",
                                                             hasTracking: true,
                                                             isSelected: false,
                                                             isPickupFree: true,
                                                             deliveryDays: 2,
                                                             deliveryDateGuaranteed: false) : nil,
                                adultSignatureRate: signatureRequirement == .adultSignatureRequired ?
                                    ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                                             insurance: "100",
                                                             retailRate: 46.96,
                                                             rate: 46.96,
                                                             rateID: "rate_a8a29d5f34984722942f466c30ea27ej",
                                                             serviceID: "",
                                                             carrierID: "usps",
                                                             shipmentID: "",
                                                             hasTracking: true,
                                                             isSelected: false,
                                                             isPickupFree: true,
                                                             deliveryDays: 2,
                                                             deliveryDateGuaranteed: false) : nil)
    }
}
