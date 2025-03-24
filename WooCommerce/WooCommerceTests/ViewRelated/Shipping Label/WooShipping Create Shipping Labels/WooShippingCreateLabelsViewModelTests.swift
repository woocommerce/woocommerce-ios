import XCTest
@testable import WooCommerce
@testable import Networking
import WooFoundation
import Yosemite

final class WooShippingCreateLabelsViewModelTests: XCTestCase {
    private let settings = WooShippingAccountSettings(storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                              dimensionUnit: "cm",
                                                                                              weightUnit: "g",
                                                                                              originCountry: "VN"),
                                                      accountSettings: .fake())

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

    func test_state_is_loading_initially() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(), stores: stores)

        // Then
        XCTAssertEqual(viewModel.state, .loading)
    }

    func test_state_is_missingRequiredData_when_store_settings_are_missing() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let error = NetworkError.notFound(response: nil)
        let originAddress = WooShippingOriginAddress.fake().copy(id: "default", defaultAddress: true)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                completion(.failure(error))
            case .loadConfig(_, _, let completion):
                completion(.success(WooShippingConfig.fake()))
            case .loadPackages, .verifyDestinationAddress:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let shippingSettingsService = MockShippingSettingsService(dimensionUnit: nil, weightUnit: nil)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(),
                                                         shippingSettingsService: shippingSettingsService,
                                                         stores: stores)

        // Then
        waitUntil {
            viewModel.state != .loading
        }
        XCTAssertEqual(viewModel.state, .missingRequiredData)
    }

    func test_state_is_missingRequiredData_when_origin_addresses_are_missing() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let error = NetworkError.notFound(response: nil)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.failure(error))
            case .loadAccountSettings(_, let completion):
                completion(.failure(error))
            case .loadConfig(_, _, let completion):
                completion(.success(WooShippingConfig.fake()))
            case .loadPackages, .verifyDestinationAddress:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let shippingSettingsService = MockShippingSettingsService()

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(),
                                                         shippingSettingsService: shippingSettingsService,
                                                         stores: stores)

        // Then
        waitUntil {
            viewModel.state != .loading
        }
        XCTAssertEqual(viewModel.state, .missingRequiredData)
        XCTAssertEqual(viewModel.dimensionsUnit, shippingSettingsService.dimensionUnit)
        XCTAssertEqual(viewModel.weightUnit, shippingSettingsService.weightUnit)
    }

    func test_state_is_ready_when_loading_required_data_succeeds() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddress = WooShippingOriginAddress(id: "default_address",
                                               company: "HEADQUARTERS",
                                               address1: "15 ALGONKIN ST",
                                               address2: "STE 100",
                                               city: "TICONDEROGA",
                                               state: "NY",
                                               postcode: "12883-1487",
                                               country: "US",
                                               phone: "223-456-7890",
                                               firstName: "JANE",
                                               lastName: "DOE",
                                               email: "TEST@EXAMPLE.COM",
                                               defaultAddress: true,
                                               isVerified: false)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadConfig(_, _, let completion):
                completion(.success(WooShippingConfig.fake()))
            case .loadPackages, .verifyDestinationAddress:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let shippingSettingsService = MockShippingSettingsService(dimensionUnit: nil, weightUnit: nil)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(),
                                                         shippingSettingsService: shippingSettingsService,
                                                         stores: stores)

        // Then
        waitUntil {
            viewModel.state != .loading && viewModel.originAddress.isNotEmpty
        }
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.dimensionsUnit, settings.storeOptions.dimensionUnit)
        XCTAssertEqual(viewModel.weightUnit, settings.storeOptions.weightUnit)
        XCTAssertEqual(viewModel.originAddresses.addresses, [originAddress])
    }

    func test_origin_unverified_state_is_correct() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddress = WooShippingOriginAddress(id: "default_address",
                                                     company: "HEADQUARTERS",
                                                     address1: "15 ALGONKIN ST",
                                                     address2: "STE 100",
                                                     city: "TICONDEROGA",
                                                     state: "NY",
                                                     postcode: "12883-1487",
                                                     country: "US",
                                                     phone: "223-456-7890",
                                                     firstName: "JANE",
                                                     lastName: "DOE",
                                                     email: "TEST@EXAMPLE.COM",
                                                     defaultAddress: true,
                                                     isVerified: false)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .verifyDestinationAddress, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let shippingSettingsService = MockShippingSettingsService(dimensionUnit: nil, weightUnit: nil)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(),
                                                         shippingSettingsService: shippingSettingsService,
                                                         stores: stores)
        XCTAssertFalse(viewModel.isOriginAddressUnverified)
        XCTAssertNil(viewModel.originAddressUnverifiedNoticeLabel)

        // Then
        waitUntil {
            viewModel.originAddress.isNotEmpty
        }
        XCTAssertTrue(viewModel.isOriginAddressUnverified)
        XCTAssertNotNil(viewModel.originAddressUnverifiedNoticeLabel)
    }

    func test_editSelectedOriginAddress_sets_addressToEdit_view_model() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddress = WooShippingOriginAddress(id: "default_address",
                                                     company: "HEADQUARTERS",
                                                     address1: "15 ALGONKIN ST",
                                                     address2: "STE 100",
                                                     city: "TICONDEROGA",
                                                     state: "NY",
                                                     postcode: "12883-1487",
                                                     country: "US",
                                                     phone: "223-456-7890",
                                                     firstName: "JANE",
                                                     lastName: "DOE",
                                                     email: "TEST@EXAMPLE.COM",
                                                     defaultAddress: true,
                                                     isVerified: false)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .verifyDestinationAddress, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let shippingSettingsService = MockShippingSettingsService(dimensionUnit: nil, weightUnit: nil)

        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(),
                                                         shippingSettingsService: shippingSettingsService,
                                                         stores: stores)

        // When
        waitUntil {
            viewModel.originAddress.isNotEmpty
        }
        viewModel.editSelectedOriginAddress()

        // Then
        XCTAssertNotNil(viewModel.addressToEdit)
        XCTAssertEqual(viewModel.addressToEdit?.company.value, originAddress.company)
        XCTAssertEqual(viewModel.addressToEdit?.address.value, originAddress.combinedAddress)
        XCTAssertEqual(viewModel.addressToEdit?.city.value, originAddress.city)
        XCTAssertEqual(viewModel.addressToEdit?.country.value, originAddress.country)
        XCTAssertEqual(viewModel.addressToEdit?.phone.value, originAddress.phone)
        XCTAssertEqual(viewModel.addressToEdit?.name.value, originAddress.fullName)
        XCTAssertEqual(viewModel.addressToEdit?.email.value, originAddress.email)
        XCTAssertEqual(viewModel.addressToEdit?.isDefaultAddress, originAddress.defaultAddress)
    }

    func test_customsFormRequired_when_origin_and_destination_in_US_then_returns_false() {
        // Given
        let originAddress = WooShippingOriginAddress(id: "default_address",
                                               company: "HEADQUARTERS",
                                               address1: "15 ALGONKIN ST",
                                               address2: "STE 100",
                                               city: "TICONDEROGA",
                                               state: "NY",
                                               postcode: "12883-1487",
                                               country: "US",
                                               phone: "223-456-7890",
                                               firstName: "JANE",
                                               lastName: "DOE",
                                               email: "TEST@EXAMPLE.COM",
                                               defaultAddress: true,
                                               isVerified: false)

        let address = Address.fake().copy(address1: "1 Main Street", city: "San Francisco", state: "CA", postcode: "12345", country: "US")
        let order = Order.fake().copy(shippingAddress: address)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, selectedOriginAddress: originAddress)

        // Then
        XCTAssertFalse(viewModel.customsFormRequired)
    }

    func test_customsFormRequired_when_origin_address_is_US_military_then_returns_true() {
        // Given
        let originAddress = WooShippingOriginAddress(id: "default_address",
                                               company: "HEADQUARTERS",
                                               address1: "15 ALGONKIN ST",
                                               address2: "STE 100",
                                               city: "TICONDEROGA",
                                               state: "AA",
                                               postcode: "12883-1487",
                                               country: "US",
                                               phone: "223-456-7890",
                                               firstName: "JANE",
                                               lastName: "DOE",
                                               email: "TEST@EXAMPLE.COM",
                                               defaultAddress: true,
                                               isVerified: false)

        let address = Address.fake().copy(address1: "1 Main Street", city: "San Francisco", state: "CA", postcode: "12345", country: "US")
        let order = Order.fake().copy(shippingAddress: address)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, selectedOriginAddress: originAddress)

        // Then
        XCTAssertTrue(viewModel.customsFormRequired)
    }

    func test_customsFormRequired_when_destination_address_is_US_military_then_returns_true() {
        // Given
        let originAddress = WooShippingOriginAddress(id: "default_address",
                                               company: "HEADQUARTERS",
                                               address1: "15 ALGONKIN ST",
                                               address2: "STE 100",
                                               city: "TICONDEROGA",
                                               state: "NY",
                                               postcode: "12883-1487",
                                               country: "US",
                                               phone: "223-456-7890",
                                               firstName: "JANE",
                                               lastName: "DOE",
                                               email: "TEST@EXAMPLE.COM",
                                               defaultAddress: true,
                                               isVerified: false)

        let address = Address.fake().copy(address1: "1 Main Street", city: "Military City", state: "AA", postcode: "12345", country: "US")
        let order = Order.fake().copy(shippingAddress: address)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, selectedOriginAddress: originAddress)

        // Then
        XCTAssertTrue(viewModel.customsFormRequired)
    }

    func test_customsFormRequired_when_destination_address_is_not_in_US_then_returns_true() {
        // Given
        let originAddress = WooShippingOriginAddress(id: "default_address",
                                               company: "HEADQUARTERS",
                                               address1: "15 ALGONKIN ST",
                                               address2: "STE 100",
                                               city: "TICONDEROGA",
                                               state: "NY",
                                               postcode: "12883-1487",
                                               country: "US",
                                               phone: "223-456-7890",
                                               firstName: "JANE",
                                               lastName: "DOE",
                                               email: "TEST@EXAMPLE.COM",
                                               defaultAddress: true,
                                               isVerified: false)

        let address = Address.fake().copy(address1: "1 Main Street", city: "London", state: "LD", postcode: "12345", country: "GB")
        let order = Order.fake().copy(shippingAddress: address)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, selectedOriginAddress: originAddress)

        // Then
        XCTAssertTrue(viewModel.customsFormRequired)
    }

    func test_itnMissingNoticeLabel_when_customs_form_is_not_required() {
        // Given
        let originAddress = WooShippingOriginAddress(id: "default_address",
                                               company: "HEADQUARTERS",
                                               address1: "15 ALGONKIN ST",
                                               address2: "STE 100",
                                               city: "TICONDEROGA",
                                               state: "NY",
                                               postcode: "12883-1487",
                                               country: "US",
                                               phone: "223-456-7890",
                                               firstName: "JANE",
                                               lastName: "DOE",
                                               email: "TEST@EXAMPLE.COM",
                                               defaultAddress: true,
                                               isVerified: false)

        let address = Address.fake().copy(address1: "1 Main Street", city: "San Francisco", state: "CA", postcode: "12345", country: "US")
        let order = Order.fake().copy(shippingAddress: address)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, selectedOriginAddress: originAddress)

        // Then
        XCTAssertNil(viewModel.itnMissingNoticeLabel)
    }

    func test_itnMissingNoticeLabel_when_customs_form_is_required() {
        // Given
        let originAddress = WooShippingOriginAddress(id: "default_address",
                                               company: "HEADQUARTERS",
                                               address1: "15 ALGONKIN ST",
                                               address2: "STE 100",
                                               city: "TICONDEROGA",
                                               state: "NY",
                                               postcode: "12883-1487",
                                               country: "US",
                                               phone: "223-456-7890",
                                               firstName: "JANE",
                                               lastName: "DOE",
                                               email: "TEST@EXAMPLE.COM",
                                               defaultAddress: true,
                                               isVerified: false)

        let address = Address.fake().copy(address1: "1 Main Street", city: "London", state: "LD", postcode: "12345", country: "GB")
        let order = Order.fake().copy(shippingAddress: address)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, selectedOriginAddress: originAddress)

        // Then
        XCTAssertNil(viewModel.itnMissingNoticeLabel)

        // When: destination country is updated to require ITN
        viewModel.customsFormViewModel.updateDestinationCountry(code: "IR")

        // Then
        XCTAssertNotNil(viewModel.itnMissingNoticeLabel)
    }

    func test_origin_addresses_fetched_and_converted_to_originAddresses_view_model() {
        // Given
        let originAddress = WooShippingOriginAddress.fake().copy(id: "default", defaultAddress: true)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .loadOriginAddresses(_, completion) = action {
                completion(.success([originAddress]))
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(), stores: stores)

        // Then
        waitUntil {
            viewModel.originAddresses.addresses.count == 1
        }
        XCTAssertEqual(viewModel.originAddresses.selectedAddressID, originAddress.id)
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
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .verifyDestinationAddress, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(), stores: stores)

        // Then
        waitUntil {
            viewModel.originAddress.isNotEmpty
        }
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

    func test_order_destination_address_is_loaded_from_remote_and_set_as_destination_address() {
        // Given
        let destinationAddresses = WooShippingNormalizedAddress.fake().copy(country: "US",
                                                                            state: "CA",
                                                                            address1: "123 Main Street",
                                                                            city: "San Francisco",
                                                                            postcode: "12345")
        let order = Order.fake()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .verifyDestinationAddress(_, _, let completion):
                completion(.success(WooShippingVerifyDestinationAddressSuccess(normalizedAddress: destinationAddresses,
                                                                               isTrivialNormalization: nil,
                                                                               isVerified: true)))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .loadOriginAddresses, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, stores: stores)

        // Then
        let expectedAddressLines = [destinationAddresses.address1,
                                    "\(destinationAddresses.city) \(destinationAddresses.state) \(destinationAddresses.postcode)",
                                    destinationAddresses.country]
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
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .loadOriginAddresses, .verifyDestinationAddress, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let markOrderComplete: Bool = waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: Address.fake()),
                                                             selectedOriginAddress: WooShippingOriginAddress.fake(),
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
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .loadOriginAddresses, .verifyDestinationAddress, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let markOrderComplete: Bool = waitFor { promise in
            let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: Address.fake()),
                                                             selectedOriginAddress: WooShippingOriginAddress.fake(),
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

    func test_isPurchaseButtonEnabled_true_when_required_fields_are_set() throws {
        // Given
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: Address.fake()),
                                                         selectedOriginAddress: WooShippingOriginAddress.fake(),
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
                                                         selectedOriginAddress: WooShippingOriginAddress.fake(),
                                                         selectedPackage: samplePackageData(),
                                                         selectedRate: sampleSelectedRate(),
                                                         stores: stores)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, completion):
                completion(.success(expectedShippingLabel))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .loadOriginAddresses, .verifyDestinationAddress, .loadConfig:
                break
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
                                                         selectedOriginAddress: WooShippingOriginAddress.fake(),
                                                         selectedPackage: samplePackageData(),
                                                         selectedRate: sampleSelectedRate(),
                                                         stores: stores)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, completion):
                isPurchasingLabelDuringPurchase = viewModel.isPurchasingLabel
                completion(.success(ShippingLabel.fake()))
            case let .loadLabelRates(_, _, _, _, packages, completion):
                completion(packages, .success([]))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .loadOriginAddresses, .verifyDestinationAddress, .loadConfig:
                break
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
        let address = Address.fake().copy(address1: "1 Main Street", city: "San Francisco", state: "CA", postcode: "12345", country: "US")
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(shippingAddress: address),
                                                         selectedOriginAddress: WooShippingOriginAddress.fake(),
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
                case .loadAccountSettings(_, let completion):
                    completion(.success(self.settings))
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

        let order = Order.fake()

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order)
        viewModel.onCustomsFormFilled(form: form)

        // Then
        XCTAssertTrue(viewModel.customsInformationIsCompleted)

        // When: destination country requires ITN
        viewModel.customsFormViewModel.updateDestinationCountry(code: "IR")

        // Then
        XCTAssertFalse(viewModel.customsInformationIsCompleted)
    }

    func test_destinationAddressStatus_unverified_and_noticeLabel_set_for_unverified_address() {
        // Given
        let address = Address.fake().copy(address1: "1 Main Street", city: "San Francisco", state: "CA", postcode: "12345", country: "US")
        let order = Order.fake().copy(shippingAddress: address)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .verifyDestinationAddress(_, _, let completion):
                completion(.success(WooShippingVerifyDestinationAddressSuccess(normalizedAddress: WooShippingNormalizedAddress.fake(),
                                                                               isTrivialNormalization: false,
                                                                               isVerified: false)))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .loadOriginAddresses, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, stores: stores)

        // Then
        XCTAssertEqual(viewModel.destinationAddressStatus, .unverified)
        XCTAssertNotNil(viewModel.destinationAddressStatusNoticeLabel)
    }

    func test_destinationAddressStatus_verified_and_noticeLabel_set_for_verified_address() {
        // Given
        let address = Address.fake().copy(address1: "1 Main Street", city: "San Francisco", state: "CA", postcode: "12345", country: "US")
        let order = Order.fake().copy(shippingAddress: address)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .verifyDestinationAddress(_, _, let completion):
                completion(.success(WooShippingVerifyDestinationAddressSuccess(normalizedAddress: WooShippingNormalizedAddress.fake(),
                                                                               isTrivialNormalization: nil,
                                                                               isVerified: true)))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .loadOriginAddresses, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, stores: stores)

        // Then
        XCTAssertEqual(viewModel.destinationAddressStatus, .verified)
        XCTAssertNotNil(viewModel.destinationAddressStatusNoticeLabel)
    }

    func test_destinationAddressStatus_missing_and_noticeLabel_set_for_empty_address() {
        // Given
        let order = Order.fake().copy(shippingAddress: nil)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .verifyDestinationAddress(_, _, let completion):
                completion(.failure(WooShippingAddressValidationError(addressError: nil,
                                                                      generalError: nil,
                                                                      nameError: nil)))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .loadOriginAddresses, .loadConfig:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, stores: stores)

        // Then
        XCTAssertEqual(viewModel.destinationAddressStatus, .missing)
        XCTAssertNotNil(viewModel.destinationAddressStatusNoticeLabel)
    }

    func test_editDestinationAddress_sets_addressToEdit_view_model() throws {
        // Given
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake())

        // When
        viewModel.editDestinationAddress()

        // Then
        XCTAssertNotNil(viewModel.addressToEdit)
    }

    func test_hazmatNotice_is_updated_after_setting_new_hazmat_category() {
        // Given
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake())
        XCTAssertNil(viewModel.hazmatNotice)

        // When
        viewModel.hazmatCategory = .class1

        // Then
        waitUntil {
            viewModel.hazmatNotice != nil
        }
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
