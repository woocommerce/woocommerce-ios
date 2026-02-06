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
        viewModel.selectPackage(samplePackageData())
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())

        // Then
        XCTAssertTrue(viewModel.isPurchaseButtonEnabled)
    }

    func test_isPurchaseButtonEnabled_false_when_destination_phone_is_invalid() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(
            sampleDestinationAddress(country: "US", state: "CA", phone: "123-4567")
        )

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())
        viewModel.selectPackage(samplePackageData())
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())

        // Then
        XCTAssertFalse(viewModel.isPurchaseButtonEnabled)
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

    func test_selecting_extra_shipping_rate_sets_expected_shippingRates() throws {
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
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate(carbonNeutral: true,
                                                                    saturdayDelivery: true,
                                                                    additionalHandling: true))

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 4)
        XCTAssertEqual(viewModel.shippingRates[0].title, "USPS - Parcel Select Mail (base fee)")
        XCTAssertEqual(viewModel.shippingRates[0].amount, "$40.06")
        XCTAssertEqual(viewModel.shippingRates[1].title, "Carbon Neutral")
        XCTAssertEqual(viewModel.shippingRates[1].amount, "$5.50")
        XCTAssertEqual(viewModel.shippingRates[2].title, "Additional Handling")
        XCTAssertEqual(viewModel.shippingRates[2].amount, "$3.75")
        XCTAssertEqual(viewModel.shippingRates[3].title, "Saturday Delivery")
        XCTAssertEqual(viewModel.shippingRates[3].amount, "$8.25")
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
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, _, completion):
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
            case let .purchaseShippingLabel(_, _, _, _, package, _, _, _, _, completion):
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
        let index = "shipment_" + viewModel.shipment.index.description
        let shipmentDetails = encodedHazmat?[index] as? [String: Any]
        XCTAssertEqual(shipmentDetails?["isHazmat"] as? Bool, true)
        XCTAssertEqual(shipmentDetails?["category"] as? String, ShippingLabelHazmatCategory.class3.rawValue)
    }

    @MainActor
    func test_purchaseLabel_triggers_onLabelPurchase_with_correct_purchased_shipping_label() async throws {
        // Given
        let expectedShippingLabel = ShippingLabel.fake().copy(carrierID: "usps", trackingNumber: "1234567890")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        var purchasedLabel: ShippingLabel?
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
                                                            stores: stores,
                                                            onLabelPurchase: { purchasedLabel = $0 })

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, _, completion):
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
        XCTAssertNotNil(purchasedLabel)
        XCTAssertEqual(purchasedLabel?.originAddress, originAddressSubject.value?.toShippingLabelAddress())
        XCTAssertEqual(purchasedLabel?.destinationAddress, destinationAddressSubject.value?.toShippingLabelAddress())
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

    func test_changing_customs_form_loads_new_label_rates_with_updated_customs_form() {
        // Given
        let expectedItem = ShippingLabelCustomsForm.Item.fake().copy(
            description: "Shirt",
            quantity: 2,
            value: 9.99,
            weight: 0.5,
            originCountry: "US",
            productID: 1
        )

        let expectedCustomsForm = ShippingLabelCustomsForm.fake().copy(contentsType: .gift,
                                                                       restrictionType: .quarantine,
                                                                       nonDeliveryOption: .abandon,
                                                                       items: [expectedItem])
        var sentCustomsForm: ShippingLabelCustomsForm?
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, _):
                sentCustomsForm = packages.first?.customsForm
            case .loadOriginAddresses(_, let completion):
                completion(.success([]))
            case .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let countries = [
            Country(code: "US", name: "United States", states: []),
            Country(code: "CA", name: "Canada", states: [])
        ]
        storageManager.insertSampleCountries(readOnlyCountries: countries)

        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(
            sampleOriginAddress(country: "US", state: "NY")
        )

        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(
            sampleDestinationAddress(country: "US", state: "CA")
        )

        let viewModel = WooShippingShipmentDetailsViewModel(
            order: Order.fake(),
            shipment: sampleShipment,
            shippingLabel: nil,
            originAddress: originAddressSubject.eraseToAnyPublisher(),
            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
            stores: stores,
            storageManager: storageManager,
            debounceDuration: 0
        )

        // When
        viewModel.selectPackage(samplePackageData())
        viewModel.customsFormViewModel.contentType = .gift
        viewModel.customsFormViewModel.restrictionType = .quarantine
        viewModel.customsFormViewModel.onDismiss()

        // Then
        waitUntil {
            sentCustomsForm != nil
        }
        XCTAssertEqual(sentCustomsForm, expectedCustomsForm)
    }

    func test_changing_HAZMAT_category_loads_new_label_rates_with_updated_HAZMAT_category() {
        // Given
        let expectedHAZMATCategory = "CLASS_1"
        var sentHAZMATCategory: String?
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, _):
                sentHAZMATCategory = packages.first?.hazmatCategory
            case .loadOriginAddresses(_, let completion):
                completion(.success([]))
            case .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

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
        viewModel.hazmatCategory = .class1

        // Then
        waitUntil {
            sentHAZMATCategory != nil
        }
        XCTAssertEqual(sentHAZMATCategory, expectedHAZMATCategory)
    }

    func test_totalCost_has_expected_value_when_shipping_rate_is_set() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())
        let rate = WooShippingSelectedRate(rate: MockShippingLabelCarrierRate.makeRate(rate: 12.2),
                                           signatureRate: nil,
                                           adultSignatureRate: MockShippingLabelCarrierRate.makeRate(rate: 40.06),
                                           carbonNeutralRate: MockShippingLabelCarrierRate.makeRate(rate: 32.34),
                                           saturdayDeliveryRate: MockShippingLabelCarrierRate.makeRate(rate: 22.77),
                                           additionalHandlingRate: MockShippingLabelCarrierRate.makeRate(rate: 18.12))

        // When
        viewModel.shippingService?.onSelectRate?(rate)

        // Then
        XCTAssertEqual(viewModel.totalCost, "$76.69")
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

    @MainActor
    func test_refreshPackagesAndShippingRates_updates_selected_package_and_rate() async throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
                                                            stores: stores)
        let package = samplePackageData()
        viewModel.selectPackage(package)
        let rate = ShippingLabelCarrierRate.fake().copy(
            title: "Rate",
            rate: 20.11,
            serviceID: "test_rate"
        )
        viewModel.shipmentWeight = "1.5"
        viewModel.shippingService?.onSelectRate?(WooShippingSelectedRate(rate: rate))

        // Confidence check
        XCTAssertEqual(viewModel.selectedPackage?.id, package.id)
        XCTAssertEqual(viewModel.selectedRate?.rate.rate, rate.rate)

        // When: package is refreshed
        let expectedRate = rate.copy(rate: 22.11)
        let updatedPackage = WooShippingCustomPackage(id: "small_flat_box",
                                                      name: "custom",
                                                      rawType: "box",
                                                      dimensions: "21.91 x 13.65 x 4.13",
                                                      boxWeight: 0.25)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadPackages(_, let completion):
                completion(.success(WooShippingPackagesResponse(siteID: 123,
                                                                customPackages: [updatedPackage],
                                                                savedPredefinedPackages: [],
                                                                allPredefinedOptions: [])))
            case let .loadLabelRates(_, _, _, _, packages, completion):
                let result = ShippingLabelCarriersAndRates(
                    packageID: "0",
                    defaultRates: [expectedRate],
                    signatureRequired: [expectedRate.copy(rate: 23.33)],
                    adultSignatureRequired: [expectedRate.copy(rate: 25.78)],
                    carbonNeutral: [],
                    saturdayDelivery: [],
                    additionalHandling: []
                )
                completion(packages, .success([result]))
            default:
                break
            }
        }
        try await viewModel.refreshPackagesAndShippingRates()

        // Then
        XCTAssertEqual(viewModel.shipmentWeight, "1.5") // shipment weight is persisted if manually entered
        XCTAssertEqual(viewModel.selectedPackage?.name, updatedPackage.name)
        XCTAssertEqual(viewModel.selectedRate?.rate.rate, expectedRate.rate)
    }

    func test_changing_origin_address_resets_selected_rate() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())
        XCTAssertNotNil(viewModel.selectedRate, "Precondition failed: selectedRate should not be nil")

        // When
        originAddressSubject.send(sampleOriginAddress(country: "US", state: "FL"))

        // Then
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.shippingService?.selectedRate)
    }

    func test_changing_destination_address_resets_selected_rate() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())
        XCTAssertNotNil(viewModel.selectedRate, "Precondition failed: selectedRate should not be nil")

        // When
        destinationAddressSubject.send(sampleDestinationAddress(country: "US", state: "FL"))

        // Then
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.shippingService?.selectedRate)
    }

    func test_changing_shipment_weight_resets_selected_rate() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())
        XCTAssertNotNil(viewModel.selectedRate, "Precondition failed: selectedRate should not be nil")

        // When
        viewModel.shipmentWeight = "10"

        // Then
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.shippingService?.selectedRate)
    }

    func test_changing_hazmat_category_resets_selected_rate() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())
        XCTAssertNotNil(viewModel.selectedRate, "Precondition failed: selectedRate should not be nil")

        // When
        viewModel.hazmatCategory = .class1

        // Then
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.shippingService?.selectedRate)
    }

    func test_changing_customs_form_resets_selected_rate() throws {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())
        XCTAssertNotNil(viewModel.selectedRate, "Precondition failed: selectedRate should not be nil")

        // When
        viewModel.customsFormViewModel.returnToSenderIfNotDelivered = true
        viewModel.customsFormViewModel.onDismiss()

        // Then
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.shippingService?.selectedRate)
    }

    // MARK: - Customs
    func test_preselects_customs_origin_country() throws {
        // Setup
        let originAddressSubject = PassthroughSubject<WooShippingAddress?, Never>()
        let destinationAddressSubject = PassthroughSubject<WooShippingAddress?, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()

        // Given
        let expectedCountry = "US"

        let countries = [
            Country(code: "US", name: "United States", states: []),
            Country(code: "CA", name: "Canada", states: [])
        ]
        storageManager.insertSampleCountries(readOnlyCountries: countries)

        let viewModel = WooShippingShipmentDetailsViewModel(
            order: Order.fake(),
            shipment: sampleShipment,
            shippingLabel: nil,
            originAddress: originAddressSubject.eraseToAnyPublisher(),
            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
            stores: stores,
            storageManager: storageManager
        )

        let customsItemViewModel = try XCTUnwrap(viewModel.customsFormViewModel.itemsViewModels.first)

        // When
        originAddressSubject.send(sampleOriginAddress(country: expectedCountry, state: ""))

        // Then
        XCTAssertEqual(customsItemViewModel.selectedCountry?.code, expectedCountry)
    }

    func test_customs_form_is_incomplete_when_destination_country_is_eu_and_hsTariffNumber_is_empty() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()

        let originAddressSubject = PassthroughSubject<WooShippingAddress?, Never>()
        let destinationAddressSubject = PassthroughSubject<WooShippingAddress?, Never>()

        let usCountry = Country(code: "US", name: "United States", states: [])
        let caCountry = Country(code: "CA", name: "Canada", states: [])
        let euCountries = [
            Country(code: "FR", name: "France", states: []),
            Country(code: "DE", name: "Germany", states: []),
            Country(code: "ES", name: "Spain", states: []),
            Country(code: "IT", name: "Italy", states: []),
            Country(code: "NL", name: "Netherlands", states: [])
        ]
        storageManager.insertSampleCountries(readOnlyCountries: [usCountry, caCountry] + euCountries)

        let item = ShippingLabelPackageItem(
            productOrVariationID: 1,
            orderItemID: 1,
            name: "Test Item",
            weight: 1,
            quantity: 1,
            value: 10, // low value, shouldn't require HS Tariff # based on value
            dimensions: .fake(),
            attributes: [],
            imageURL: nil
        )
        let shipment = Shipment(
            contents: [CollapsibleShipmentItemCardViewModel(item: item, currency: "USD")],
            currency: "USD",
            currencySettings: ServiceLocator.currencySettings,
            shippingSettingsService: ServiceLocator.shippingSettingsService
        )

        let viewModel = WooShippingShipmentDetailsViewModel(
            order: Order.fake(),
            shipment: shipment,
            shippingLabel: nil,
            originAddress: originAddressSubject.eraseToAnyPublisher(),
            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
            stores: stores,
            storageManager: storageManager
        )

        // When
        let itemViewModel = viewModel.customsFormViewModel.itemsViewModels[0]
        itemViewModel.hsTariffNumber = "" // Empty tariff number

        originAddressSubject.send(sampleOriginAddress(country: usCountry.code, state: ""))
        destinationAddressSubject.send(sampleDestinationAddress(country: caCountry.code, state: ""))

        // Then: HS Tariff number should not be required for non EU destination countries regardless of value
        XCTAssertTrue(
            itemViewModel.requiredInformationIsEntered,
            "HS Tariff number should not be required for \(usCountry.name)"
        )

        // And: HS Tariff number should be required for EU countries regardless of value
        for euCountry in euCountries {
            destinationAddressSubject.send(sampleDestinationAddress(country: euCountry.code, state: ""))
            XCTAssertFalse(
                itemViewModel.requiredInformationIsEntered,
                "HS Tariff number should be required for \(euCountry.name)"
            )
        }
    }

    func test_package_contains_complete_customs_form_when_required_data_is_prefilled() throws {
        // Setup
        let originAddressSubject = PassthroughSubject<WooShippingAddress?, Never>()
        let destinationAddressSubject = PassthroughSubject<WooShippingAddress?, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()

        // Given
        let originCountry = Country(code: "US", name: "United States", states: [])
        let destinationCountry = Country(code: "CA", name: "Canada", states: [])

        let countries = [
            originCountry,
            destinationCountry
        ]
        storageManager.insertSampleCountries(readOnlyCountries: countries)

        let shipment = sampleShipment

        let viewModel = WooShippingShipmentDetailsViewModel(
            order: Order.fake(),
            shipment: shipment,
            shippingLabel: nil,
            originAddress: originAddressSubject.eraseToAnyPublisher(),
            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
            stores: stores,
            storageManager: storageManager
        )

        // When
        destinationAddressSubject.send(sampleDestinationAddress(country: destinationCountry.code, state: ""))
        originAddressSubject.send(sampleOriginAddress(country: originCountry.code, state: ""))

        viewModel.selectPackage(samplePackageData())

        // Then
        XCTAssertTrue(viewModel.customsInformationIsCompleted)

        waitUntil {
            guard let customsForm = viewModel.currentPackage?.customsForm else {
                return false
            }

            let customsFormItem = customsForm.items[0]
            let shipmentItem = shipment.items[0]

            return customsFormItem.description == shipmentItem.name &&
            customsFormItem.value == shipmentItem.value &&
            customsFormItem.weight == shipmentItem.weight &&
            customsFormItem.originCountry == originCountry.code
        }
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
                           email: nil,
                           phone: "",
                           country: country,
                           state: state,
                           address1: "15 ALGONKIN ST",
                           address2: "STE 100",
                           city: "TICONDEROGA",
                           postcode: "12883-1487"
        )
    }

    func sampleDestinationAddress(country: String, state: String, phone: String = "234-567-8901") -> WooShippingAddress {
        WooShippingAddress(company: "",
                           name: "",
                           email: nil,
                           phone: phone,
                           country: country,
                           state: state,
                           address1: "1 Main Street",
                           address2: "",
                           city: "San Francisco",
                           postcode: "12345")
    }

    func sampleSelectedRate(with signatureRequirement: WooShippingServiceCardViewModel.SignatureRequirement = .none,
                           carbonNeutral: Bool = false,
                           saturdayDelivery: Bool = false,
                           additionalHandling: Bool = false) -> WooShippingSelectedRate {
        WooShippingSelectedRate(
            rate: ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
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
            signatureRate: signatureRequirement == .signatureRequired ? ShippingLabelCarrierRate.fake().copy(rate: 42.76) : nil,
            adultSignatureRate: signatureRequirement == .adultSignatureRequired ? ShippingLabelCarrierRate.fake().copy(rate: 46.96) : nil,
            carbonNeutralRate: carbonNeutral ? ShippingLabelCarrierRate.fake().copy(rate: 45.56) : nil,
            saturdayDeliveryRate: saturdayDelivery ? ShippingLabelCarrierRate.fake().copy(rate: 48.31) : nil,
            additionalHandlingRate: additionalHandling ? ShippingLabelCarrierRate.fake().copy(rate: 43.81) : nil
        )
    }
}
