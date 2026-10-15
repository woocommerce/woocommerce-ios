import XCTest
import Combine
import ParcelFittingCheck
import YosemiteTestHelpers
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

    func test_isPurchaseButtonEnabled_when_domestic_USPS_rate_and_destination_phone_empty_then_returns_true() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(
            sampleDestinationAddress(country: "US", state: "CA", phone: "")
        )
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // When
        viewModel.selectPackage(samplePackageData())
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())

        // Then
        XCTAssertTrue(viewModel.isPurchaseButtonEnabled)
    }

    func test_isPurchaseButtonEnabled_when_FedEx_rate_and_destination_phone_empty_then_returns_false() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(
            sampleDestinationAddress(country: "US", state: "CA", phone: "")
        )
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())
        let fedExRate = WooShippingSelectedRate(rate: ShippingLabelCarrierRate.fake().copy(title: "FedEx Ground Economy",
                                                                                            carrierID: "fedex"))

        // When
        viewModel.selectPackage(samplePackageData())
        viewModel.shippingService?.onSelectRate?(fedExRate)

        // Then
        XCTAssertFalse(viewModel.isPurchaseButtonEnabled)
    }

    func test_isPurchaseButtonEnabled_when_international_and_destination_phone_empty_then_returns_false() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(
            sampleDestinationAddress(country: "GB", state: "LD", phone: "")
        )
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // When
        viewModel.customsFormViewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.customsFormViewModel.contentType = .documents
        viewModel.customsFormViewModel.restrictionType = .quarantine
        XCTAssertTrue(viewModel.customsInformationIsCompleted)
        viewModel.selectPackage(samplePackageData())
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())

        // Then
        XCTAssertFalse(viewModel.isPurchaseButtonEnabled)
    }

    @MainActor
    func test_purchaseLabel_when_FedEx_rate_and_destination_phone_empty_then_does_not_purchase() async throws {
        // Given
        var purchaseRequested = false
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(
            sampleDestinationAddress(country: "US", state: "CA", phone: "")
        )
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, _, completion) = action {
                purchaseRequested = true
                completion(.success(ShippingLabel.fake()))
            }
        }
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
                                                            stores: stores)
        let fedExRate = WooShippingSelectedRate(rate: ShippingLabelCarrierRate.fake().copy(title: "FedEx Ground Economy",
                                                                                            carrierID: "fedex"))

        // When
        viewModel.selectPackage(samplePackageData())
        viewModel.shippingService?.onSelectRate?(fedExRate)
        try await viewModel.purchaseLabel()

        // Then
        XCTAssertFalse(purchaseRequested)
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
        var encodedHazmat: RequestParameterDictionary?
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
        guard case let .dictionary(shipmentDetails)? = encodedHazmat?[index] else {
            return XCTFail("Expected hazmat details for shipment")
        }
        XCTAssertEqual(shipmentDetails["isHazmat"], .bool(true))
        XCTAssertEqual(shipmentDetails["category"], .string(ShippingLabelHazmatCategory.class3.rawValue))
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

    @MainActor
    func test_changing_customs_form_when_rates_are_loaded_then_sends_new_form_once() async {
        // Given
        var sentCustomsForms: [ShippingLabelCustomsForm?] = []
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .checkEUProductIdentifiersRequirement(_, _, _, completion):
                completion(.notRequired)
            case let .loadLabelRates(_, _, _, _, packages, completion):
                sentCustomsForms.append(packages.first?.customsForm)
                completion(packages, .success([]))
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
            Country(code: "VN", name: "Vietnam", states: [])
        ]
        storageManager.insertSampleCountries(readOnlyCountries: countries)

        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(
            sampleOriginAddress(country: "US", state: "NY")
        )

        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(
            sampleDestinationAddress(country: "VN", state: "")
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

        viewModel.selectPackage(samplePackageData())

        // When
        await until { !sentCustomsForms.isEmpty }
        await until { viewModel.customsFormViewModel.requiredInformationIsEntered }
        viewModel.customsFormViewModel.onDismiss()
        await until { sentCustomsForms.contains { $0?.contentsType == .merchandise } }
        let requestCountBeforeChange = sentCustomsForms.count

        viewModel.customsFormViewModel.contentType = .gift
        viewModel.customsFormViewModel.onDismiss()

        // Then
        await until {
            sentCustomsForms.count > requestCountBeforeChange
        }
        XCTAssertEqual(sentCustomsForms.last.flatMap { $0?.contentsType }, .gift)

        // When
        let requestCountAfterChange = sentCustomsForms.count
        viewModel.customsFormViewModel.onDismiss()

        // Then
        XCTAssertEqual(sentCustomsForms.count, requestCountAfterChange)
    }

    @MainActor
    func test_changing_destination_from_domestic_to_international_when_customs_form_exists_then_includes_form_in_label_rates() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        storageManager.insertSampleCountries(readOnlyCountries: [Country(code: "US", name: "United States", states: []),
                                                                 Country(code: "VN", name: "Vietnam", states: [])])
        var sentCustomsForms: [ShippingLabelCustomsForm?] = []
        var requirementCompletion: ((WooShippingEUProductIdentifiersRequirement) -> Void)?
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, completion):
                sentCustomsForms.append(packages.first?.customsForm)
                completion(packages, .success([]))
            case let .checkEUProductIdentifiersRequirement(_, _, _, completion):
                requirementCompletion = completion
            case .loadOriginAddresses(_, let completion):
                completion(.success([]))
            case .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let destinationAddress = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: Just(sampleOriginAddress(country: "US", state: "NY")).eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddress.eraseToAnyPublisher(),
                                                            stores: stores,
                                                            storageManager: storageManager,
                                                            debounceDuration: 0)
        viewModel.selectPackage(samplePackageData())

        // When
        await until { !sentCustomsForms.isEmpty }
        await until { viewModel.customsFormViewModel.requiredInformationIsEntered }
        viewModel.customsFormViewModel.contentType = .documents
        viewModel.customsFormViewModel.restrictionType = .quarantine
        viewModel.customsFormViewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.customsFormViewModel.onDismiss()
        await until { sentCustomsForms.count > 1 }
        let requestCountAfterFormEmission = sentCustomsForms.count
        viewModel.customsFormViewModel.onDismiss()
        XCTAssertEqual(sentCustomsForms.count, requestCountAfterFormEmission)
        destinationAddress.send(sampleDestinationAddress(country: "VN", state: ""))

        // Then
        await until {
            sentCustomsForms.count > requestCountAfterFormEmission && sentCustomsForms.last.flatMap { $0 } != nil
        }
        XCTAssertEqual(sentCustomsForms.last.flatMap { $0?.contentsType }, .documents)
        XCTAssertNotNil(requirementCompletion)
    }

    func test_changing_customs_form_loads_new_label_rates_without_customs_form_when_customs_form_is_not_required() {
        // Given
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
            Country(code: "US", name: "United States", states: [])
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
        waitUntil {
            stores.receivedActions.contains { action in
                guard let action = action as? WooShippingAction,
                      case .loadLabelRates = action else {
                    return false
                }
                return true
            }
        }
        stores.reset()

        viewModel.customsFormViewModel.contentType = .gift
        viewModel.customsFormViewModel.restrictionType = .quarantine
        viewModel.customsFormViewModel.onDismiss()

        // Then
        waitUntil {
            stores.receivedActions.contains { action in
                guard let action = action as? WooShippingAction,
                      case .loadLabelRates = action else {
                    return false
                }
                return true
            }
        }
        XCTAssertNil(sentCustomsForm)
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

    func test_shouldShowCustomsForm_when_destination_is_unnormalized_US_territory_then_returns_true() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "PR"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertTrue(viewModel.shouldShowCustomsForm)
    }

    func test_shouldShowCustomsForm_when_origin_and_destination_are_same_unnormalized_US_territory_then_returns_false() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "US", state: "PR"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "PR"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertFalse(viewModel.shouldShowCustomsForm)
    }

    func test_shouldShowCustomsForm_when_origin_and_destination_are_same_territory_with_mixed_encoding_then_returns_false() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleOriginAddress(country: "PR", state: ""))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "PR"))

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
        viewModel.customsFormViewModel.contentType = .documents
        viewModel.customsFormViewModel.restrictionType = .quarantine
        viewModel.customsFormViewModel.itemsViewModels.first?.requiredInformationIsEntered = true

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
        viewModel.customsFormViewModel.contentType = .documents
        viewModel.customsFormViewModel.itemsViewModels.forEach { $0.requiredInformationIsEntered = true }
        viewModel.customsFormViewModel.onDismiss()

        // Then
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.shippingService?.selectedRate)
    }

    func test_EU_product_identifier_requirement_check_when_route_is_international_then_sends_order_and_origin_ID() {
        // Given
        let order = Order.fake()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var receivedOrderID: Int64?
        var receivedOriginID: String?
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            guard case let .checkEUProductIdentifiersRequirement(_, orderID, originID, completion) = action else { return }
            receivedOrderID = orderID
            receivedOriginID = originID
            completion(.required(prefills: [:]))
        }

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: order,
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: Just(sampleOriginAddress(country: "US", state: "NY")).eraseToAnyPublisher(),
                                                            destinationAddress: Just(sampleDestinationAddress(country: "GB", state: "LD")).eraseToAnyPublisher(),
                                                            originAddressID: Just("origin-123").eraseToAnyPublisher(),
                                                            stores: stores)

        // Then
        XCTAssertEqual(receivedOrderID, order.orderID)
        XCTAssertEqual(receivedOriginID, "origin-123")
        XCTAssertFalse(viewModel.isCheckingEUProductIdentifiers)
        XCTAssertTrue(viewModel.customsFormViewModel.asksForEUProductIdentifiers)
    }

    func test_EU_product_identifier_requirement_check_when_route_changes_before_result_then_discards_stale_result() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var requirementCompletions: [(WooShippingEUProductIdentifiersRequirement) -> Void] = []
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            guard case let .checkEUProductIdentifiersRequirement(_, _, _, completion) = action else { return }
            requirementCompletions.append(completion)
        }
        let destinationAddress = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "GB", state: "LD"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: Just(sampleOriginAddress(country: "US", state: "NY")).eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddress.eraseToAnyPublisher(),
                                                            stores: stores)

        // When
        destinationAddress.send(sampleDestinationAddress(country: "DE", state: "BE"))
        XCTAssertEqual(requirementCompletions.count, 2)
        requirementCompletions[1](.required(prefills: [:]))
        requirementCompletions[0](.notRequired)

        // Then
        XCTAssertEqual(viewModel.customsFormViewModel.euProductIdentifiersRequirement, .required(prefills: [:]))
        XCTAssertTrue(viewModel.customsFormViewModel.asksForEUProductIdentifiers)
    }

    func test_EU_product_identifier_requirement_check_when_purchased_shipment_is_refunded_then_checks_again() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var requirementChecks = 0
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            guard case let .checkEUProductIdentifiersRequirement(_, _, _, completion) = action else { return }
            requirementChecks += 1
            completion(.notRequired)
        }
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: .fake(),
                                                            originAddress: Just(sampleOriginAddress(country: "US", state: "NY")).eraseToAnyPublisher(),
                                                            destinationAddress: Just(sampleDestinationAddress(country: "GB", state: "LD")).eraseToAnyPublisher(),
                                                            stores: stores)
        XCTAssertEqual(requirementChecks, 0)

        // When
        viewModel.didRequestRefund(for: 123)

        // Then
        XCTAssertEqual(requirementChecks, 1)
    }

    @MainActor
    func test_purchaseLabel_when_requirement_check_is_pending_then_blocks_purchase_but_keeps_loading_rates() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        storageManager.insertSampleCountries(readOnlyCountries: [
            Country(code: "US", name: "United States", states: []),
            Country(code: "GB", name: "United Kingdom", states: [])
        ])
        var ratesRequested = false
        var purchaseRequested = false
        var requirementCompletion: ((WooShippingEUProductIdentifiersRequirement) -> Void)?
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .checkEUProductIdentifiersRequirement(_, _, _, completion):
                requirementCompletion = completion
            case let .loadLabelRates(_, _, _, _, packages, completion):
                ratesRequested = true
                completion(packages, .success([]))
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, _, completion):
                purchaseRequested = true
                completion(.success(.fake()))
            case .loadConfig, .loadOriginAddresses, .loadPackages, .verifyDestinationAddress:
                break
            default:
                break
            }
        }
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: Just(sampleOriginAddress(country: "US", state: "NY")).eraseToAnyPublisher(),
                                                            destinationAddress: Just(sampleDestinationAddress(country: "GB", state: "LD")).eraseToAnyPublisher(),
                                                            stores: stores,
                                                            storageManager: storageManager,
                                                            debounceDuration: 0)
        viewModel.selectPackage(samplePackageData())

        // When
        await until { ratesRequested }
        await until { viewModel.customsInformationIsCompleted }
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())

        // Then
        XCTAssertTrue(viewModel.customsInformationIsCompleted)
        XCTAssertNotNil(viewModel.selectedRate)

        // When
        try await viewModel.purchaseLabel()

        // Then
        XCTAssertTrue(viewModel.isCheckingEUProductIdentifiers)
        XCTAssertFalse(viewModel.isPurchaseButtonEnabled)
        XCTAssertFalse(purchaseRequested)

        // When
        requirementCompletion?(.notRequired)
        await until { !viewModel.isCheckingEUProductIdentifiers && viewModel.customsInformationIsCompleted }
        viewModel.shippingService?.onSelectRate?(sampleSelectedRate())
        try await viewModel.purchaseLabel()

        // Then
        XCTAssertTrue(purchaseRequested)
    }

    func test_EU_product_identifier_requirement_check_when_route_changes_then_checks_again() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var requirementChecks = 0
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            guard case let .checkEUProductIdentifiersRequirement(_, _, _, completion) = action else { return }
            requirementChecks += 1
            completion(.notRequired)
        }
        let destinationAddress = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "GB", state: "LD"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: Just(sampleOriginAddress(country: "US", state: "NY")).eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddress.eraseToAnyPublisher(),
                                                            stores: stores)

        // When
        destinationAddress.send(sampleDestinationAddress(country: "GB", state: "LD").copy(postcode: "W1A 1AA"))

        // Then
        XCTAssertEqual(requirementChecks, 2)
        XCTAssertFalse(viewModel.isCheckingEUProductIdentifiers)
    }

    func test_EU_product_identifier_requirement_check_when_route_is_unchanged_then_does_not_check_again() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var requirementChecks = 0
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            guard case let .checkEUProductIdentifiersRequirement(_, _, _, completion) = action else { return }
            requirementChecks += 1
            completion(.notRequired)
        }
        let originAddress = sampleOriginAddress(country: "US", state: "NY")
        let destinationAddress = sampleDestinationAddress(country: "GB", state: "LD")
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(originAddress)
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(destinationAddress)
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
                                                            originAddressID: Just("origin-123").eraseToAnyPublisher(),
                                                            stores: stores)
        XCTAssertEqual(requirementChecks, 1)

        // When
        originAddressSubject.send(originAddress)
        destinationAddressSubject.send(destinationAddress)

        // Then
        XCTAssertEqual(requirementChecks, 1)
    }

    func test_EU_product_identifier_requirement_check_when_only_origin_ID_changes_then_checks_with_new_ID() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var receivedOriginIDs: [String?] = []
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            guard case let .checkEUProductIdentifiersRequirement(_, _, originID, completion) = action else { return }
            receivedOriginIDs.append(originID)
            completion(.notRequired)
        }
        let originID = CurrentValueSubject<String?, Never>("origin-123")
        let originAddress = sampleOriginAddress(country: "US", state: "NY")
        let destinationAddress = sampleDestinationAddress(country: "GB", state: "LD")
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: Just(originAddress).eraseToAnyPublisher(),
                                                            destinationAddress: Just(destinationAddress).eraseToAnyPublisher(),
                                                            originAddressID: originID.eraseToAnyPublisher(),
                                                            stores: stores)

        // When
        originID.send("origin-456")

        // Then
        XCTAssertEqual(receivedOriginIDs, ["origin-123", "origin-456"])
        _ = viewModel
    }

    func test_EU_product_identifier_requirement_check_when_route_is_domestic_or_label_is_purchased_then_does_not_dispatch() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var requirementChecks = 0
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case .checkEUProductIdentifiersRequirement = action {
                requirementChecks += 1
            }
        }

        // When
        _ = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                shipment: sampleShipment,
                                                shippingLabel: nil,
                                                originAddress: Just(sampleOriginAddress(country: "US", state: "NY")).eraseToAnyPublisher(),
                                                destinationAddress: Just(sampleDestinationAddress(country: "US", state: "CA")).eraseToAnyPublisher(),
                                                stores: stores)
        _ = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                shipment: sampleShipment,
                                                shippingLabel: .fake(),
                                                originAddress: Just(sampleOriginAddress(country: "US", state: "NY")).eraseToAnyPublisher(),
                                                destinationAddress: Just(sampleDestinationAddress(country: "GB", state: "LD")).eraseToAnyPublisher(),
                                                stores: stores)

        // Then
        XCTAssertEqual(requirementChecks, 0)
    }

    @MainActor
    func test_EU_product_identifier_requirement_check_when_route_becomes_domestic_then_does_not_emit_customs_form() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        storageManager.insertSampleCountries(readOnlyCountries: [Country(code: "US", name: "United States", states: []),
                                                                 Country(code: "GB", name: "United Kingdom", states: [])])
        var requirementChecks = 0
        var sentCustomsForms: [ShippingLabelCustomsForm?] = []
        let prefills: [Int64: WooShippingEUProductIdentifiers] = [
            1: WooShippingEUProductIdentifiers(productID: 1,
                                               sku: "shirt-sku",
                                               manufacturerProductID: "shirt-part",
                                               standardizedProductID: "1234567890123")
        ]
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .checkEUProductIdentifiersRequirement(_, _, _, completion):
                requirementChecks += 1
                completion(.required(prefills: prefills))
            case let .loadLabelRates(_, _, _, _, packages, completion):
                sentCustomsForms.append(packages.first?.customsForm)
                completion(packages, .success([]))
            case .loadOriginAddresses(_, let completion):
                completion(.success([]))
            case .loadConfig:
                break
            default:
                break
            }
        }
        let destinationAddress = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "GB", state: "LD"))
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: Just(sampleOriginAddress(country: "US", state: "NY")).eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddress.eraseToAnyPublisher(),
                                                            stores: stores,
                                                            storageManager: storageManager,
                                                            debounceDuration: 0)
        viewModel.selectPackage(samplePackageData())

        // When
        await until { sentCustomsForms.contains { $0 != nil } }
        await until { viewModel.customsInformationIsCompleted }

        // Then
        XCTAssertTrue(viewModel.customsInformationIsCompleted)
        XCTAssertTrue(viewModel.customsFormViewModel.asksForEUProductIdentifiers)
        XCTAssertNotNil(sentCustomsForms.last.flatMap { $0 })
        let labelRateRequestsBeforeRouteChange = sentCustomsForms.count

        // When
        destinationAddress.send(sampleDestinationAddress(country: "US", state: "CA"))

        // Then
        XCTAssertEqual(requirementChecks, 1, "The domestic route should not dispatch a requirement check")
        await until {
            sentCustomsForms.count > labelRateRequestsBeforeRouteChange && sentCustomsForms.last.flatMap { $0 } == nil
        }
        XCTAssertNil(sentCustomsForms.last.flatMap { $0 }, "Domestic routes should not send customs data with rates")
        XCTAssertTrue(viewModel.customsFormViewModel.asksForEUProductIdentifiers,
                      "A domestic route should not overwrite the existing customs form requirement")
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
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .checkEUProductIdentifiersRequirement(_, _, _, completion) = action {
                completion(.notRequired)
            }
        }

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

    func test_currentPackage_does_not_contain_prefilled_customs_form_when_customs_form_is_not_required() throws {
        // Setup
        let originAddressSubject = PassthroughSubject<WooShippingAddress?, Never>()
        let destinationAddressSubject = PassthroughSubject<WooShippingAddress?, Never>()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()

        // Given
        let originCountry = Country(code: "US", name: "United States", states: [])
        storageManager.insertSampleCountries(readOnlyCountries: [originCountry])

        let viewModel = WooShippingShipmentDetailsViewModel(
            order: Order.fake(),
            shipment: sampleShipment,
            shippingLabel: nil,
            originAddress: originAddressSubject.eraseToAnyPublisher(),
            destinationAddress: destinationAddressSubject.eraseToAnyPublisher(),
            stores: stores,
            storageManager: storageManager
        )

        // When
        destinationAddressSubject.send(sampleDestinationAddress(country: originCountry.code, state: "CA"))
        originAddressSubject.send(sampleOriginAddress(country: originCountry.code, state: "NY"))

        viewModel.selectPackage(samplePackageData())

        // Then
        waitUntil {
            viewModel.customsFormViewModel.requiredInformationIsEntered
        }
        viewModel.customsFormViewModel.onDismiss()
        XCTAssertNil(viewModel.currentPackage?.customsForm)
    }

    func test_parcelFittingDidConfirm_when_called_then_sets_package_and_caches_AR_state() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(nil)
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(nil)
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                             shipment: sampleShipment,
                                                             shippingLabel: nil,
                                                             originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                             destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        let package = ParcelPresetPackage(id: "usps_medium", name: "Medium Box", length: 11, width: 8.5, height: 5.5)
        let carrier = ParcelPresetCarrier(id: "usps", name: "USPS", packages: [package])
        let measurement = ParcelDimensions(length: 10, width: 8, height: 5)
        let result = ParcelFittingResult.carrierPackage(package, measurement: measurement)

        // When
        viewModel.parcelFittingDidConfirm(result,
                                           carriers: [carrier],
                                           starredPackageIDs: ["usps_medium"],
                                           dimensionUnit: .inches)

        // Then
        XCTAssertNotNil(viewModel.selectedPackage)
        XCTAssertEqual(viewModel.selectedPackage?.id, "usps_medium")
        XCTAssertNotNil(viewModel.lastARState)
        XCTAssertNotNil(viewModel.lastARState?.measurement)
        XCTAssertEqual(viewModel.lastARState?.carriers.count, 1)
        XCTAssertTrue(viewModel.lastARState?.starredPackageIDs.contains("usps_medium") == true)
        XCTAssertEqual(viewModel.lastARState?.dimensionUnit, .inches)
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
