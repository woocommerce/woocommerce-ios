import XCTest
import Combine
@testable import WooCommerce
@testable import Networking
import WooFoundation
import Yosemite

final class WooShippingShipmentDetailsViewModelTests: XCTestCase {

    func test_customsFormRequired_when_origin_and_destination_in_US_then_returns_false() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertFalse(viewModel.customsFormRequired)
    }

    func test_customsFormRequired_when_origin_address_is_US_military_then_returns_true() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "AA"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "CA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertTrue(viewModel.customsFormRequired)
    }

    func test_customsFormRequired_when_destination_address_is_US_military_then_returns_true() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "US", state: "AA"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertTrue(viewModel.customsFormRequired)
    }

    func test_customsFormRequired_when_destination_address_is_not_in_US_then_returns_true() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "GB", state: "LD"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())

        // Then
        XCTAssertTrue(viewModel.customsFormRequired)
    }

    func test_itnMissingNoticeLabel_when_customs_form_is_not_required() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
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
        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
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

    func test_selectPackage_sets_selectedPackage_with_package_data() {
        // Given
        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
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
        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
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
        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
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
                case .loadAccountSettings(_, let completion):
                    completion(.success(self.sampleSettings))
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

    func test_customsInformationIsCompleted_when_custom_form_is_filled() {
        // Given
        let form = ShippingLabelCustomsForm(packageID: "",
                                            packageName: "",
                                            contentsType: .documents,
                                            contentExplanation: "",
                                            restrictionType: .quarantine,
                                            restrictionComments: "",
                                            nonDeliveryOption: .abandon,
                                            itn: "",
                                            items: [])

        let originAddressSubject = CurrentValueSubject<WooShippingOriginAddress?, Never>(sampleOriginAddress(country: "US", state: "NY"))
        let destinationAddressSubject = CurrentValueSubject<WooShippingAddress?, Never>(sampleDestinationAddress(country: "GB", state: "LD"))

        // When
        let viewModel = WooShippingShipmentDetailsViewModel(order: Order.fake(),
                                                            shipment: sampleShipment,
                                                            shippingLabel: nil,
                                                            originAddress: originAddressSubject.eraseToAnyPublisher(),
                                                            destinationAddress: destinationAddressSubject.eraseToAnyPublisher())
        viewModel.onCustomsFormFilled(form: form)

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

    var sampleSettings: WooShippingAccountSettings {
        WooShippingAccountSettings(storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                           dimensionUnit: "cm",
                                                                           weightUnit: "g",
                                                                           originCountry: "VN"),
                                   accountSettings: .fake())
    }

    func sampleOriginAddress(country: String, state: String) -> WooShippingOriginAddress {
        WooShippingOriginAddress(id: "default_address",
                                 company: "HEADQUARTERS",
                                 address1: "15 ALGONKIN ST",
                                 address2: "STE 100",
                                 city: "TICONDEROGA",
                                 state: state,
                                 postcode: "12883-1487",
                                 country: country,
                                 phone: "223-456-7890",
                                 firstName: "JANE",
                                 lastName: "DOE",
                                 email: "TEST@EXAMPLE.COM",
                                 defaultAddress: true,
                                 isVerified: false)
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
}
