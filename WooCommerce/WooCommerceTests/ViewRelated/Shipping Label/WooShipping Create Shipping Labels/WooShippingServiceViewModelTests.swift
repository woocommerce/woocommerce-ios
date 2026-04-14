import XCTest
@testable import WooCommerce
import Yosemite
import enum Networking.NetworkError

final class WooShippingServiceViewModelTests: XCTestCase {

    private var stores: MockStoresManager!

    private static let samplePackageID = "default_box"
    private var samplePackage = ShippingLabelPackageSelected.fake().copy(id: samplePackageID, weight: 5)

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, completion):
                completion(packages, .success(self.sampleLabelRates()))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }
    }

    func test_init_sets_expected_values() {
        // Given
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: WooShippingAddress.fake())

        // Then
        XCTAssertNil(viewModel.selectedRate)
        XCTAssertEqual(viewModel.loadingState, .empty)
    }

    func test_loadLabelRates_generates_service_tabs_with_expected_data() throws {
        // Given
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        var loadingResult: Result<Void, Error>?
        viewModel.loadLabelRates(for: samplePackage, onLoadingCompletion: { loadingResult = $0 })

        // Then
        XCTAssert(loadingResult?.isSuccess == true)
        XCTAssertEqual(viewModel.loadingState, .loaded)

        XCTAssertEqual(viewModel.serviceTabs.count, 2)
        XCTAssertEqual(viewModel.serviceTabs[0].cards.count, 2)
        XCTAssertEqual(viewModel.serviceTabs[1].cards.count, 1)

        let rate = try XCTUnwrap(viewModel.serviceTabs[0].cards[0])
        XCTAssertEqual(rate.selected, false)
        XCTAssertEqual(rate.signatureRequirement, .none)
        XCTAssertEqual(rate.title, "USPS - Media Mail")
        XCTAssertEqual(rate.daysToDeliveryLabel, "7 business days")
        XCTAssertEqual(rate.rateLabel, "$7.53")
        XCTAssertEqual(rate.carrierLogo, WooShippingCarrier.usps.logo)
        XCTAssertEqual(rate.trackingLabel, "Tracking")
        XCTAssertEqual(rate.insuranceLabel, "Insurance (up to $100.00)")
        XCTAssertEqual(rate.freePickupLabel, "Free pickup")
        XCTAssertEqual(rate.extraInfoLabel, "Includes tracking, insurance (up to $100.00), free pickup")
        XCTAssertNil(rate.signatureRequiredLabel)
        XCTAssertNil(rate.adultSignatureRequiredLabel)

        let rate2 = try XCTUnwrap(viewModel.serviceTabs[0].cards[1])
        XCTAssertEqual(rate2.selected, false)
        XCTAssertEqual(rate2.signatureRequirement, .none)
        XCTAssertEqual(rate2.title, "USPS - Parcel Select Mail")
        XCTAssertEqual(rate2.daysToDeliveryLabel, "2 business days")
        XCTAssertEqual(rate2.rateLabel, "$40.06")
        XCTAssertEqual(rate2.carrierLogo, WooShippingCarrier.usps.logo)
        XCTAssertEqual(rate2.trackingLabel, "Tracking")
        XCTAssertEqual(rate2.insuranceLabel, "Insurance (up to $100.00)")
        XCTAssertEqual(rate2.freePickupLabel, "Free pickup")
        XCTAssertEqual(rate2.extraInfoLabel, "Includes tracking, insurance (up to $100.00), free pickup")
        XCTAssertEqual(rate2.signatureRequiredLabel, "Signature Required (+$2.70)")
        XCTAssertEqual(rate2.adultSignatureRequiredLabel, "Adult Signature Required (+$6.90)")

        let rate3 = try XCTUnwrap(viewModel.serviceTabs[1].cards[0])
        XCTAssertEqual(rate3.selected, false)
        XCTAssertEqual(rate3.signatureRequirement, .none)
        XCTAssertEqual(rate3.title, "DHL - Next Day")
        XCTAssertEqual(rate3.daysToDeliveryLabel, "1 business day")
        XCTAssertEqual(rate3.rateLabel, "$14.22")
        XCTAssertEqual(rate3.carrierLogo, WooShippingCarrier.dhlExpress.logo)
        XCTAssertEqual(rate3.trackingLabel, "Tracking")
        XCTAssertEqual(rate3.insuranceLabel, "Insurance (up to $100.00)")
        XCTAssertEqual(rate3.freePickupLabel, "Free pickup")
        XCTAssertEqual(rate3.extraInfoLabel, "Includes tracking, insurance (up to $100.00), free pickup")
        XCTAssertNil(rate3.signatureRequiredLabel)
        XCTAssertNil(rate3.adultSignatureRequiredLabel)
    }

    func test_when_loadLabelRates_receives_error_it_sets_error_state() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, completion):
                completion(packages, .failure(NetworkError.timeout()))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        var loadingResult: Result<Void, Error>?
        viewModel.loadLabelRates(for: samplePackage, onLoadingCompletion: { loadingResult = $0 })

        // Then
        XCTAssertEqual(viewModel.loadingState, .error(.failedLoadingLabelRates))
        XCTAssertTrue(viewModel.serviceTabs.isEmpty)
        XCTAssert(loadingResult?.isFailure == true)
        XCTAssertEqual(loadingResult?.failure as? WooShippingServiceViewModel.Error,
                       WooShippingServiceViewModel.Error.failedLoadingLabelRates)
    }

    func test_selecting_standard_rate_updates_expected_values() {
        // Given
        let standardRate = sampleStandardRates()[1]
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage)
        viewModel.selectRate(standardRate,
                             signatureRate: nil,
                             adultSignatureRate: nil,
                             carbonNeutralRate: nil,
                             saturdayDeliveryRate: nil,
                             additionalHandlingRate: nil)

        // Then
        XCTAssertNotNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.selectedRate?.signatureRate)
        XCTAssertNil(viewModel.selectedRate?.adultSignatureRate)
        XCTAssertNil(viewModel.selectedRate?.carbonNeutralRate)
        XCTAssertNil(viewModel.selectedRate?.saturdayDeliveryRate)
        XCTAssertNil(viewModel.selectedRate?.additionalHandlingRate)
        XCTAssertEqual(viewModel.selectedRate?.rate.title, standardRate.title)
        XCTAssertEqual(viewModel.serviceTabs[0].cards[1].selected, true)
    }

    func test_selecting_service_card_signature_rate_updates_expected_values() {
        // Given
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)
        // When
        viewModel.loadLabelRates(for: samplePackage)
        viewModel.selectRate(sampleStandardRates()[1],
                             signatureRate: sampleSignatureRates().first,
                             adultSignatureRate: nil,
                             carbonNeutralRate: nil,
                             saturdayDeliveryRate: nil,
                             additionalHandlingRate: nil)

        // Then
        XCTAssertNotNil(viewModel.selectedRate)
        XCTAssertNotNil(viewModel.selectedRate?.signatureRate)
        XCTAssertNil(viewModel.selectedRate?.adultSignatureRate)
        XCTAssertEqual(viewModel.serviceTabs[0].cards[1].selected, true)
    }

    func test_selecting_service_card_adult_signature_rate_updates_expected_values() {
        // Given
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage)
        viewModel.selectRate(sampleStandardRates()[1],
                             signatureRate: nil,
                             adultSignatureRate: sampleAdultSignatureRates().first,
                             carbonNeutralRate: nil,
                             saturdayDeliveryRate: nil,
                             additionalHandlingRate: nil)

        // Then
        XCTAssertNotNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.selectedRate?.signatureRate)
        XCTAssertNotNil(viewModel.selectedRate?.adultSignatureRate)
        XCTAssertEqual(viewModel.serviceTabs[0].cards[1].selected, true)
    }

    func test_selecting_service_card_extra_rate_updates_expected_values() {
        // Given
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage)
        viewModel.selectRate(sampleStandardRates()[1],
                             signatureRate: nil,
                             adultSignatureRate: nil,
                             carbonNeutralRate: MockShippingLabelCarrierRate.makeRate(rate: 45.99),
                             saturdayDeliveryRate: MockShippingLabelCarrierRate.makeRate(rate: 22.4),
                             additionalHandlingRate: MockShippingLabelCarrierRate.makeRate(rate: 20.53))

        // Then
        XCTAssertNotNil(viewModel.selectedRate)
        XCTAssertNil(viewModel.selectedRate?.signatureRate)
        XCTAssertNil(viewModel.selectedRate?.adultSignatureRate)
        XCTAssertNotNil(viewModel.selectedRate?.carbonNeutralRate)
        XCTAssertNotNil(viewModel.selectedRate?.saturdayDeliveryRate)
        XCTAssertNotNil(viewModel.selectedRate?.additionalHandlingRate)
        XCTAssertEqual(viewModel.serviceTabs[0].cards[1].selected, true)
    }

    func test_selecting_rate_calls_onSelectRate() {
        // Given
        var selectedRate: WooShippingSelectedRate?
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores) { rate in
            selectedRate = rate
        }

        // When
        viewModel.loadLabelRates(for: samplePackage)
        viewModel.selectRate(sampleStandardRates()[1],
                             signatureRate: nil,
                             adultSignatureRate: nil,
                             carbonNeutralRate: nil,
                             saturdayDeliveryRate: nil,
                             additionalHandlingRate: nil)

        // Then
        XCTAssertEqual(selectedRate?.rate, sampleStandardRates()[1])
    }

    func test_sortShipping_by_price_returns_sorted_list() {
        // Given
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage)
        viewModel.sortShipping(by: .price)

        // Then
        let uspsCards = viewModel.serviceTabs.first?.cards
        XCTAssertEqual(uspsCards?.count, 2)
        XCTAssertEqual(uspsCards?.first?.title, "USPS - Media Mail")
    }

    func test_sortShipping_by_deliveryDays_returns_sorted_list() {
        // Given
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage)
        viewModel.sortShipping(by: .deliveryTime)

        // Then
        let uspsCards = viewModel.serviceTabs.first?.cards
        XCTAssertEqual(uspsCards?.count, 2)
        XCTAssertEqual(uspsCards?.first?.title, "USPS - Parcel Select Mail")
    }

    func test_it_sets_correct_error_state_when_destination_address_is_missing() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, completion):
                completion(packages, .failure(NetworkError.timeout()))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: WooShippingAddress.fake(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage)

        // Then
        XCTAssertEqual(viewModel.loadingState, .error(.missingDestinationAddress))
    }

    func test_it_sets_correct_error_state_when_total_shipment_weight_is_zero() {
        // Given
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage.copy(weight: 0))

        // Then
        XCTAssertEqual(viewModel.loadingState, .error(.missingShipmentWeight))
    }

    func test_when_loadLabelRates_receives_empty_rates_it_sets_error_state() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let emptyRates = [ShippingLabelCarriersAndRates(packageID: Self.samplePackageID,
                                                        defaultRates: [],
                                                        signatureRequired: [],
                                                        adultSignatureRequired: [],
                                                        carbonNeutral: [],
                                                        saturdayDelivery: [],
                                                        additionalHandling: [])]
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, completion):
                completion(packages, .success(emptyRates))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage)

        // Then
        XCTAssertEqual(viewModel.loadingState, .error(.noRatesAvailable(isHAZMAT: false)))

        // When
        let updatedPackage = samplePackage.copy(hazmatCategory: "Test")
        viewModel.loadLabelRates(for: updatedPackage)

        // Then
        XCTAssertEqual(viewModel.loadingState, .error(.noRatesAvailable(isHAZMAT: true)))
    }

    func test_when_loadLabelRates_receives_invalid_destination_name_rate_error_it_sets_error_state() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let ratesWithError = [ShippingLabelCarriersAndRates(packageID: Self.samplePackageID,
                                                            defaultRates: [],
                                                            defaultErrors: [ShippingLabelRateError(
                                                                code: "rate_error",
                                                                message: "shipment.to_address: invalid name; " +
                                                                "A first and last name is required if passed in: " +
                                                                "input name needs at least 1 space character"
                                                            )],
                                                            signatureRequired: [],
                                                            adultSignatureRequired: [],
                                                            carbonNeutral: [],
                                                            saturdayDelivery: [],
                                                            additionalHandling: [])]
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, completion):
                completion(packages, .success(ratesWithError))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage)

        // Then
        XCTAssertEqual(viewModel.loadingState, .error(.invalidDestinationName))
    }

    func test_switching_tab_updates_the_card_list() {
        // Given
        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        // When
        viewModel.loadLabelRates(for: samplePackage)

        // Then
        XCTAssertEqual(viewModel.displayedServiceCards.count, 2)
        XCTAssertEqual(viewModel.displayedServiceCards.first?.title, "USPS - Media Mail")

        // When
        viewModel.selectedTabIndex = 1

        // Then
        XCTAssertEqual(viewModel.displayedServiceCards.count, 1)
        XCTAssertEqual(viewModel.displayedServiceCards.first?.title, "DHL - Next Day")
    }

    func test_refreshSelectedRate_returns_updated_rate() throws {
        // Given
        let oldStandardRate = ShippingLabelCarrierRate(title: "USPS - Media Mail",
                                                       insurance: "100",
                                                       retailRate: 8,
                                                       rate: 7.53,
                                                       rateID: "test_rateID",
                                                       serviceID: "test_serviceID",
                                                       carrierID: "usps",
                                                       shipmentID: "",
                                                       hasTracking: true,
                                                       isSelected: false,
                                                       isPickupFree: true,
                                                       deliveryDays: 7,
                                                       deliveryDateGuaranteed: false)

        let newRate = ShippingLabelCarrierRate(title: "USPS - Media Mail",
                                               insurance: "100",
                                               retailRate: 8,
                                               rate: 7.53,
                                               rateID: "updated_rateID",
                                               serviceID: "test_serviceID",
                                               carrierID: "usps",
                                               shipmentID: "",
                                               hasTracking: true,
                                               isSelected: false,
                                               isPickupFree: true,
                                               deliveryDays: 7,
                                               deliveryDateGuaranteed: false)

        let stores = MockStoresManager(sessionManager: .testingInstance)
        let updatedRates = [ShippingLabelCarriersAndRates(packageID: Self.samplePackageID,
                                                          defaultRates: [newRate],
                                                          signatureRequired: [],
                                                          adultSignatureRequired: [],
                                                          carbonNeutral: [],
                                                          saturdayDelivery: [],
                                                          additionalHandling: [])]
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, completion):
                completion(packages, .success(updatedRates))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }

        let viewModel = WooShippingServiceViewModel(order: Order.fake(),
                                                    originAddress: WooShippingAddress.fake(),
                                                    destinationAddress: sampleDestinationAddress(),
                                                    stores: stores)

        viewModel.loadLabelRates(for: samplePackage)
        viewModel.selectRate(oldStandardRate,
                             signatureRate: nil,
                             adultSignatureRate: nil,
                             carbonNeutralRate: nil,
                             saturdayDeliveryRate: nil,
                             additionalHandlingRate: nil)
        let oldSelectedRate = try XCTUnwrap(viewModel.selectedRate)

        // When
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadLabelRates(_, _, _, _, packages, completion):
                completion(packages, .success(updatedRates))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }
        viewModel.loadLabelRates(for: samplePackage)
        let updatedRate = viewModel.refreshSelectedRate(from: oldSelectedRate)

        // Then
        XCTAssertNotNil(updatedRate)
        XCTAssertNil(updatedRate?.signatureRate)
        XCTAssertNil(updatedRate?.adultSignatureRate)
        XCTAssertEqual(updatedRate?.rate.rateID, newRate.rateID)
    }
}

private extension WooShippingServiceViewModelTests {
    func sampleLabelRates() -> [ShippingLabelCarriersAndRates] {
        [ShippingLabelCarriersAndRates(packageID: Self.samplePackageID,
                                       defaultRates: sampleStandardRates(),
                                       signatureRequired: sampleSignatureRates(),
                                       adultSignatureRequired: sampleAdultSignatureRates(),
                                       carbonNeutral: [],
                                       saturdayDelivery: [],
                                       additionalHandling: [])]
    }

    func sampleStandardRates() -> [ShippingLabelCarrierRate] {
        [ShippingLabelCarrierRate(title: "USPS - Media Mail",
                                  insurance: "100",
                                  retailRate: 8,
                                  rate: 7.53,
                                  rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                  serviceID: "",
                                  carrierID: "usps",
                                  shipmentID: "",
                                  hasTracking: true,
                                  isSelected: false,
                                  isPickupFree: true,
                                  deliveryDays: 7,
                                  deliveryDateGuaranteed: false),
         ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
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
         ShippingLabelCarrierRate(title: "DHL - Next Day",
                                  insurance: "100",
                                  retailRate: 15,
                                  rate: 14.22,
                                  rateID: "rate_a8a29d5f34984722942f466c30ea27eg",
                                  serviceID: "",
                                  carrierID: "dhlexpress",
                                  shipmentID: "",
                                  hasTracking: true,
                                  isSelected: false,
                                  isPickupFree: true,
                                  deliveryDays: 1,
                                  deliveryDateGuaranteed: false)]
    }

    func sampleSignatureRates() -> [ShippingLabelCarrierRate] {
        [ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
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
                                  deliveryDateGuaranteed: false)]
    }

    func sampleAdultSignatureRates() -> [ShippingLabelCarrierRate] {
        [ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
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
                                  deliveryDateGuaranteed: false)]
    }

    func sampleDestinationAddress() -> WooShippingAddress {
        WooShippingAddress(company: "HEADQUARTERS",
                           name: "JANE DOE",
                           email: nil,
                           phone: "1-234-456-7890",
                           country: "US",
                           state: "NY",
                           address1: "15 ALGONKIN ST STE 100",
                           address2: "",
                           city: "TICONDEROGA",
                           postcode: "12883-1487")
    }
}
