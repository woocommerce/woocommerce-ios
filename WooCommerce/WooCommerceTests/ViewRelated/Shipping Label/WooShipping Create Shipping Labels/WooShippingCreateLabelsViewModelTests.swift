import XCTest
@testable import WooCommerce
@testable import Networking
import WooFoundation
import Yosemite

final class WooShippingCreateLabelsViewModelTests: XCTestCase {
    func test_inits_with_expected_values_for_shipping_label_creation() {
        // Given
        let order = Order.fake()

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order)

        // Then
        XCTAssertFalse(viewModel.markOrderComplete)
        XCTAssertFalse(viewModel.isPurchaseButtonEnabled)
        XCTAssertNil(viewModel.totalCost)
        XCTAssertFalse(viewModel.canViewLabel)
    }

    func test_inits_with_expected_values_for_viewing_purchased_label() {
        // Given
        let order = Order.fake()
        let label = ShippingLabel.fake()

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, shippingLabel: label)

        // Then
        XCTAssertNotNil(viewModel.postPurchase)
        XCTAssertFalse(viewModel.isPurchaseButtonEnabled)
        XCTAssertNotNil(viewModel.totalCost)
        XCTAssertTrue(viewModel.canViewLabel)
        XCTAssertEqual(viewModel.shippingRates.count, 1)
    }

    func test_default_origin_address_fetched_and_converted_to_formatted_originAddress() {
        // Given
        let originAddresses = [WooShippingOriginAddress.fake(),
                               WooShippingOriginAddress.fake().copy(address1: "123 Main Street",
                                                                    city: "San Francisco",
                                                                    state: "CA",
                                                                    postcode: "12345",
                                                                    country: "US",
                                                                    defaultAddress: true)]
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success(originAddresses))
            case .loadPackages:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(), stores: stores)

        // Then
        XCTAssertEqual("123 Main Street, San Francisco CA 12345, US", viewModel.originAddress)
    }

    func test_order_shipping_address_converted_to_formatted_desinationAddressLines() {
        // Given
        let address = Address.fake().copy(address1: "1 Main Street", city: "San Francisco", state: "CA", postcode: "12345", country: "US")
        let order = Order.fake().copy(shippingAddress: address)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order)

        // Then
        let expectedAddressLines = [address.address1, "\(address.city) \(address.state) \(address.postcode)", address.country]
        XCTAssertEqual(expectedAddressLines, viewModel.destinationAddressLines)
    }

    func test_order_shipping_lines_converted_to_shippingLineViewModels() {
        // Given
        let order = Order.fake().copy(currency: "GBP",
                                      shippingLines: [ShippingLine.fake().copy(shippingID: 1, total: "10"),
                                                      ShippingLine.fake().copy(shippingID: 2),
                                                      ShippingLine.fake().copy(shippingID: 3)])

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order)

        // Then
        XCTAssertEqual(order.shippingLines.map({ $0.shippingID }), viewModel.shippingLines.map({ $0.id }))
        XCTAssertEqual("£10.00", viewModel.shippingLines.first?.formattedTotal)
    }

    func test_onLabelPurchase_notifies_when_order_should_not_be_marked_complete() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, completion):
                completion(.success(ShippingLabel.fake()))
            case .loadPackages, .loadOriginAddresses:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let markOrderComplete: Bool = waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: Address.fake()),
                                                             originAddress: SiteAddress(siteSettings: self.mapLoadGeneralSiteSettingsResponse()),
                                                             selectedPackage: self.samplePackageData(),
                                                             selectedRate: self.sampleSelectedRate(),
                                                             stores: stores) { complete in
                promise(complete)
            }
            viewModel.markOrderComplete = false
            viewModel.purchaseLabel()
        }

        // Then
        XCTAssertFalse(markOrderComplete)
    }

    func test_onLabelPurchase_notifies_when_order_should_be_marked_complete() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, completion):
                completion(.success(ShippingLabel.fake()))
            case .loadPackages, .loadOriginAddresses:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let markOrderComplete: Bool = waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: Address.fake()),
                                                             originAddress: SiteAddress(siteSettings: self.mapLoadGeneralSiteSettingsResponse()),
                                                             selectedPackage: self.samplePackageData(),
                                                             selectedRate: self.sampleSelectedRate(),
                                                             stores: stores) { complete in
                promise(complete)
            }
            viewModel.markOrderComplete = true
            viewModel.purchaseLabel()
        }

        // Then
        XCTAssertTrue(markOrderComplete)
    }

    func test_canPurchaseLabel_true_when_shipping_rate_is_selected() throws {
        // Given
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: Address.fake()),
                                                         originAddress: SiteAddress(siteSettings: mapLoadGeneralSiteSettingsResponse()),
                                                         selectedPackage: samplePackageData(),
                                                         selectedRate: sampleSelectedRate())

        // Then
        XCTAssertTrue(viewModel.isPurchaseButtonEnabled)
    }

    func test_totalCost_has_expected_value_when_shipping_rate_is_set() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order, selectedRate: self.sampleSelectedRate(), currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.totalCost, "$40.06")
    }

    func test_selecting_standard_shipping_rate_sets_expected_shippingRates() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order, selectedRate: self.sampleSelectedRate(), currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 1)
        XCTAssertEqual(viewModel.shippingRates.first?.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(viewModel.shippingRates.first?.amount, "$40.06")
    }

    func test_selecting_signature_shipping_rate_sets_expected_shippingRates() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order,
                                                         selectedRate: self.sampleSelectedRate(with: .signatureRequired),
                                                         currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 2)
        XCTAssertEqual(viewModel.shippingRates[0].title, "USPS - Parcel Select Mail (base fee)")
        XCTAssertEqual(viewModel.shippingRates[0].amount, "$40.06")
        XCTAssertEqual(viewModel.shippingRates[1].title, "Signature Required")
        XCTAssertEqual(viewModel.shippingRates[1].amount, "$2.70")
    }

    func test_selecting_adult_signature_shipping_rate_sets_expected_shippingRates() throws {
        // Given
        let order = Order.fake()
        let viewModel = WooShippingCreateLabelsViewModel(order: order,
                                                         selectedRate: self.sampleSelectedRate(with: .adultSignatureRequired),
                                                         currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.shippingRates.count, 2)
        XCTAssertEqual(viewModel.shippingRates[0].title, "USPS - Parcel Select Mail (base fee)")
        XCTAssertEqual(viewModel.shippingRates[0].amount, "$40.06")
        XCTAssertEqual(viewModel.shippingRates[1].title, "Adult Signature Required")
        XCTAssertEqual(viewModel.shippingRates[1].amount, "$6.90")
    }

    func test_purchaseLabel_sets_postPurchase_with_purchased_shipping_label() {
        // Given
        let expectedShippingLabel = ShippingLabel.fake().copy(carrierID: "usps", trackingNumber: "1234567890")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: Address.fake()),
                                                         originAddress: SiteAddress(siteSettings: mapLoadGeneralSiteSettingsResponse()),
                                                         selectedPackage: samplePackageData(),
                                                         selectedRate: sampleSelectedRate(),
                                                         stores: stores)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, completion):
                completion(.success(expectedShippingLabel))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        viewModel.purchaseLabel()

        // Then
        XCTAssertNotNil(viewModel.postPurchase)
        XCTAssertEqual(viewModel.postPurchase?.pickupURL, WooShippingCarrier(rawValue: expectedShippingLabel.carrierID)?.pickupURL)
        XCTAssertEqual(viewModel.postPurchase?.trackingURL, ShippingLabelTrackingURLGenerator.url(for: expectedShippingLabel))
    }

    func test_purchaseLabel_sets_isPurchasingLabel_as_expected() {
        // Given
        var isPurchasingLabelDuringPurchase = false
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: Address.fake()),
                                                         originAddress: SiteAddress(siteSettings: mapLoadGeneralSiteSettingsResponse()),
                                                         selectedPackage: samplePackageData(),
                                                         selectedRate: sampleSelectedRate(),
                                                         stores: stores)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, completion):
                isPurchasingLabelDuringPurchase = viewModel.isPurchasingLabel
                completion(.success(ShippingLabel.fake()))
            case let .loadLabelRates(_, _, _, _, _, completion):
                completion(.success([]))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        // Check isPurchaseLabel is false before purchase
        XCTAssertFalse(viewModel.isPurchasingLabel)

        // When
        viewModel.purchaseLabel()

        // Then
        XCTAssertTrue(isPurchasingLabelDuringPurchase)
        // Check isPurchaseLabel is false after purchase
        XCTAssertFalse(viewModel.isPurchasingLabel)
    }

    func test_selectPackage_sets_selectedPackage_with_package_data() {
        // Given
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake())

        // When
        viewModel.selectPackage(samplePackageData())

        // Then
        XCTAssertNotNil(viewModel.selectedPackage)
        XCTAssertEqual(viewModel.selectedPackage?.id, samplePackageData().id)
    }

    func test_selectPackage_sets_shipmentWeight_with_items_and_package_weight() {
        // Given
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(), itemsDataSource: MockItemsDataSource())

        // When
        viewModel.selectPackage(samplePackageData())

        // Then
        XCTAssertEqual(viewModel.shipmentWeight, "1.25")
    }

    func test_changing_shipmentWeight_loads_new_label_rates_with_updated_weight() {
        // Given
        let expectedWeight = 2.5
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: Address.fake()),
                                                         originAddress: SiteAddress(siteSettings: self.mapLoadGeneralSiteSettingsResponse()),
                                                         selectedPackage: samplePackageData(),
                                                         stores: stores,
                                                         itemsDataSource: MockItemsDataSource(),
                                                         debounceDuration: 0)


        // When
        let packageWeightForLabelRates: Double? = waitFor { promise in
            stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
                switch action {
                case let .loadLabelRates(_, _, _, _, packages, _):
                    promise(packages.first?.weight)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            viewModel.shipmentWeight = expectedWeight.description
        }

        // Then
        XCTAssertEqual(packageWeightForLabelRates, expectedWeight)
    }
}

private extension WooShippingCreateLabelsViewModelTests {
    /// Returns the SiteSettings output upon receiving `filename` (Data Encoded)
    ///
    func mapGeneralSettings(from filename: String) -> [SiteSetting] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! SiteSettingsMapper(siteID: 123, settingsGroup: SiteSettingGroup.general).map(response: response)
    }

    /// Returns the SiteSetting array as output upon receiving `settings-general`
    ///
    func mapLoadGeneralSiteSettingsResponse() -> [SiteSetting] {
        return mapGeneralSettings(from: "settings-general")
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
}

private final class MockItemsDataSource: WooShippingItemsDataSource {
    var items = [ShippingLabelPackageItem(productOrVariationID: 1,
                                          name: "Shirt",
                                          weight: 0.5,
                                          quantity: 2,
                                          value: 9.99,
                                          dimensions: ProductDimensions.fake(),
                                          attributes: [],
                                          imageURL: nil)]
    var currency = "GBP"
}
