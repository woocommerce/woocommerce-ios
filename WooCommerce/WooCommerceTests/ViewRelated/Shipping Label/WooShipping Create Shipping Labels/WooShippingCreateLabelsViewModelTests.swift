import XCTest
import YosemiteTestHelpers
@testable import WooCommerce
@testable import Networking
import WooFoundation
import Yosemite
import struct NetworkingCore.AnyDecodable
import enum NetworkingCore.DotcomError
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

final class WooShippingCreateLabelsViewModelTests: XCTestCase {
    private let settings = WooShippingAccountSettings(storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                              dimensionUnit: "cm",
                                                                                              weightUnit: "g",
                                                                                              originCountry: "VN"),
                                                      accountSettings: .fake())

    private var storageManager: MockStorageManager!
    private let siteID: Int64 = 5435
    private let orderID: Int64 = 254

    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
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
        let originAddress = WooShippingOriginAddress(siteID: 123,
                                                     id: "default_address",
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

    func test_isOrderCompleted_is_correct() {
        // Given
        let order = Order.fake().copy(status: .completed)
        let viewModel = WooShippingCreateLabelsViewModel(order: order)

        // Then
        XCTAssertTrue(viewModel.isOrderCompleted)

        // Given
        let order2 = Order.fake().copy(status: .processing)
        let viewModel2 = WooShippingCreateLabelsViewModel(order: order2)

        // Then
        XCTAssertFalse(viewModel2.isOrderCompleted)
    }

    func test_origin_unverified_state_is_correct() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddress = WooShippingOriginAddress(siteID: 123,
                                                     id: "default_address",
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
        let originAddress = WooShippingOriginAddress(siteID: 123,
                                                     id: "default_address",
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
            case .loadPackages, .verifyDestinationAddress:
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
            case .loadPackages, .verifyDestinationAddress:
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
            case .loadPackages, .loadOriginAddresses:
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
            case .loadPackages, .loadOriginAddresses:
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
            case .loadPackages, .loadOriginAddresses:
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
            case .loadPackages, .loadOriginAddresses:
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

    func test_shouldShowNotices_is_updated_correctly_for_unfulfilled_shipment() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .verifyDestinationAddress(_, _, let completion):
                completion(.success(WooShippingVerifyDestinationAddressSuccess(normalizedAddress: WooShippingNormalizedAddress.fake(),
                                                                               isTrivialNormalization: nil,
                                                                               isVerified: true)))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadOriginAddresses(_, let completion):
                let originAddress = WooShippingOriginAddress.fake().copy(address1: "123 Main Street", defaultAddress: true)
                completion(.success([originAddress]))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // There exist 2 shipments, one of which has been fulfilled.
        let order = Order.fake().copy(siteID: siteID, orderID: orderID)
        let shippingLabel = ShippingLabel.fake().copy(siteID: siteID, orderID: orderID, shippingLabelID: 134)
        let shipments = [WooShippingShipment.fake().copy(siteID: siteID, orderID: orderID, index: "shipment_0", items: [.fake()], shippingLabel: shippingLabel),
                         WooShippingShipment.fake().copy(siteID: siteID, orderID: orderID, index: "shipment_1", items: [.fake()])]
        insert(shipments: shipments, order: order)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, stores: stores, storageManager: storageManager, initialNoticeDelay: .seconds(0))
        XCTAssertFalse(viewModel.shouldShowNotices)

        waitUntil {
            viewModel.state == .ready
        }

        // Then: first shipment is fulfilled
        XCTAssertFalse(viewModel.shouldShowNotices)

        // When: switching to unfulfilled shipment
        viewModel.selectedShipmentIndex = 1

        // Then
        waitUntil {
            viewModel.shouldShowNotices == true
        }
        XCTAssertNotNil(viewModel.destinationAddressStatusNoticeLabel)

        /// The notice should be dismissed after a bit
        waitUntil {
            viewModel.destinationAddressStatusNoticeLabel == nil
        }
    }

    func test_hazmatNotice_is_updated_after_setting_new_hazmat_category() {
        // Given
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake())
        XCTAssertNil(viewModel.hazmatNotice)

        // When
        viewModel.currentShipmentDetailsViewModel.hazmatCategory = .class1

        // Then
        waitUntil {
            viewModel.hazmatNotice != nil
        }
    }

    func test_destinationPhoneNumberNoticeLabel_is_missing_when_phone_is_empty() {
        // Given
        let labelDestinationAddress = ShippingLabelAddress.fake().copy(phone: "", country: "US")
        let shippingLabel = ShippingLabel.fake().copy(destinationAddress: labelDestinationAddress)
        let order = Order.fake().copy(shippingLabels: [shippingLabel])

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            preselection: .shippingLabel(
                label: shippingLabel
            )
        )

        // Then
        let expected = NSLocalizedString("wooShipping.createLabels.destinationPhoneNumber.missing",
                                         value: "Phone number is required for the destination address.",
                                         comment: "")
        waitUntil {
            viewModel.destinationPhoneNumberNoticeLabel != nil
        }
        XCTAssertEqual(viewModel.destinationPhoneNumberNoticeLabel, expected)
    }

    func test_destinationPhoneNumberNoticeLabel_is_invalid_when_phone_is_invalid_for_us() {
        // Given
        let labelDestinationAddress = ShippingLabelAddress.fake().copy(phone: "123-4567", country: "US")
        let shippingLabel = ShippingLabel.fake().copy(destinationAddress: labelDestinationAddress)
        let order = Order.fake().copy(shippingLabels: [shippingLabel])

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            preselection: .shippingLabel(
                label: shippingLabel
            )
        )

        // Then
        let expected = NSLocalizedString("wooShipping.createLabels.destinationPhoneNumber.invalid",
                                         value: "Please enter a valid phone number for the destination address.",
                                         comment: "")
        waitUntil {
            viewModel.destinationPhoneNumberNoticeLabel != nil
        }
        XCTAssertEqual(viewModel.destinationPhoneNumberNoticeLabel, expected)
    }

    @MainActor
    func test_purchaseLabel_sets_phoneNumberErrorNotice_with_generic_message() async {
        // Given
        let shippingAddress = Address(firstName: "Jane",
                                      lastName: "Doe",
                                      company: nil,
                                      address1: "123 Main Street",
                                      address2: nil,
                                      city: "San Francisco",
                                      state: "CA",
                                      postcode: "94107",
                                      country: "US",
                                      phone: "234-567-8901",
                                      email: "test@example.com")
        let originAddress = WooShippingOriginAddress.fake().copy(
            id: "default",
            company: "HEADQUARTERS",
            address1: "15 ALGONKIN ST",
            address2: "STE 100",
            city: "TICONDEROGA",
            state: "NY",
            postcode: "12883-1487",
            country: "US",
            phone: "223-456-7890",
            defaultAddress: true
        )
        insert(originAddress: originAddress)

        let destinationAddress = WooShippingNormalizedAddress.fake().copy(phone: "234-567-8901", country: "US", state: "CA")
        let order = Order.fake().copy(siteID: siteID, orderID: orderID, shippingAddress: shippingAddress)
        let paymentMethod = ShippingLabelPaymentMethod.fake().copy(
            paymentMethodID: 11743265,
            name: "Example User",
            cardType: .visa,
            cardDigits: "4242"
        )
        let accountSettings = ShippingLabelAccountSettings.fake().copy(
            paymentMethods: [paymentMethod],
            selectedPaymentMethodID: paymentMethod.paymentMethodID
        )
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .verifyDestinationAddress(_, _, let completion):
                completion(.success(WooShippingVerifyDestinationAddressSuccess(normalizedAddress: destinationAddress,
                                                                               isTrivialNormalization: nil,
                                                                               isVerified: true)))
            case let .purchaseShippingLabel(_, _, _, _, _, _, _, _, _, completion):
                let data: [String: AnyDecodable] = [
                    "message": AnyDecodable("Please enter a valid phone number.")
                ]
                completion(.failure(DotcomError.unknown(code: "wcc_server_error_response",
                                                        message: "Please enter a valid phone number.",
                                                        data: data)))
            case .loadPackages, .loadConfig:
                break
            default:
                break
            }
        }

        let viewModel = WooShippingCreateLabelsViewModel(order: order,
                                                         stores: stores,
                                                         storageManager: storageManager)
        await until {
            viewModel.state == .ready
        }
        await until {
            viewModel.currentShipmentDetailsViewModel.shippingService != nil
        }
        viewModel.didUpdateAccountSettings(accountSettings)

        let package = WooShippingPackageData(id: "small_flat_box",
                                             name: "Small Flat Rate Box",
                                             length: "21.91",
                                             width: "13.65",
                                             height: "4.13",
                                             weight: ".25",
                                             source: .predefined(sourceTitle: "usps", sourceID: "usps"),
                                             packageType: "box")
        let selectedRate = WooShippingSelectedRate(
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
            signatureRate: nil,
            adultSignatureRate: nil,
            carbonNeutralRate: nil,
            saturdayDeliveryRate: nil,
            additionalHandlingRate: nil
        )
        viewModel.currentShipmentDetailsViewModel.selectPackage(package)
        viewModel.currentShipmentDetailsViewModel.shippingService?.onSelectRate?(selectedRate)

        // When
        await viewModel.purchaseLabel(shouldRefreshPackageAndRate: false)

        // Then
        let expectedMessage = NSLocalizedString("wooShipping.createLabels.phoneNumberError.message",
                                                value: "Please enter a valid phone number for the destination address.",
                                                comment: "")
        XCTAssertEqual(viewModel.labelPurchaseErrorNotice?.message, expectedMessage)
    }

    func test_originAddressLines_is_correct_for_both_purchased_label_and_unfulfilled_shipment() {
        // Given
        let labelOriginAddress = ShippingLabelAddress.fake().copy(address1: "1 E 35th ST")
        let shippingLabel = ShippingLabel.fake().copy(shippingLabelID: 134,
                                                      shipmentID: "0",
                                                      status: .purchased,
                                                      originAddress: labelOriginAddress)
        let order = Order.fake().copy(siteID: siteID, orderID: orderID, shippingLabels: [shippingLabel])
        // There exist 2 shipments, one of which has been fulfilled.
        let shipments = [WooShippingShipment.fake().copy(siteID: siteID, orderID: orderID, index: "0", items: [.fake()], shippingLabel: shippingLabel),
                         WooShippingShipment.fake().copy(siteID: siteID, orderID: orderID, index: "1", items: [.fake()])]
        insert(shipments: shipments, order: order)

        let originAddress = WooShippingOriginAddress.fake().copy(address1: "123 Main Street",
                                                                 defaultAddress: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            default:
                break
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, stores: stores, storageManager: storageManager)
        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertEqual(viewModel.currentShipment.purchasedLabel?.shippingLabelID, shippingLabel.shippingLabelID)
        XCTAssertEqual(viewModel.originAddressLines?.first, labelOriginAddress.address1)

        // When
        viewModel.selectedShipmentIndex = 1

        // Then
        XCTAssertNil(viewModel.currentShipment.purchasedLabel)
        XCTAssertEqual(viewModel.originAddressLines?.first, originAddress.address1)
    }

    func test_destinationAddressLines_is_correct_for_both_purchased_label_and_unfulfilled_shipment() {
        // Given
        let labelDestinationAddress = ShippingLabelAddress.fake().copy(address1: "1 E 35th ST")
        let shippingLabel = ShippingLabel.fake().copy(shippingLabelID: 134,
                                                      shipmentID: "0",
                                                      status: .purchased,
                                                      destinationAddress: labelDestinationAddress)
        let order = Order.fake().copy(siteID: siteID, orderID: orderID, shippingLabels: [shippingLabel])
        let shipments = [WooShippingShipment.fake().copy(siteID: siteID, orderID: orderID, index: "0", items: [.fake()], shippingLabel: shippingLabel),
                         WooShippingShipment.fake().copy(siteID: siteID, orderID: orderID, index: "1", items: [.fake()])]
        insert(shipments: shipments, order: order)

        let destinationAddress = WooShippingNormalizedAddress.fake().copy(address1: "123 Main Street")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([WooShippingOriginAddress.fake().copy(address1: "Test address",
                                                                          defaultAddress: true)]))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .verifyDestinationAddress(_, _, let completion):
                completion(.success(WooShippingVerifyDestinationAddressSuccess(normalizedAddress: destinationAddress,
                                                                               isTrivialNormalization: nil,
                                                                               isVerified: true)))
            default:
                break
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, stores: stores, storageManager: storageManager)
        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertEqual(viewModel.currentShipment.purchasedLabel?.shippingLabelID, shippingLabel.shippingLabelID)
        XCTAssertEqual(viewModel.destinationAddressLines?.first, labelDestinationAddress.address1)

        // When
        viewModel.selectedShipmentIndex = 1

        // Then
        XCTAssertNil(viewModel.currentShipment.purchasedLabel)
        XCTAssertEqual(viewModel.destinationAddressLines?.first, destinationAddress.address1)
    }

    func test_payment_method_line_is_nil_when_shipment_is_purchased() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddress = WooShippingOriginAddress.fake().copy(
            id: "default",
            address1: "Test address line",
            defaultAddress: true
        )
        let shippingLabel = ShippingLabel.fake()
        let order = Order.fake().copy(shippingLabels: [shippingLabel])
        let shipment = Shipment(
            contents: [],
            purchasedLabel: shippingLabel,
            currency: "USD",
            currencySettings: ServiceLocator.currencySettings,
            shippingSettingsService: MockShippingSettingsService()
        )

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .verifyDestinationAddress:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: order, stores: stores)

        waitUntil {
            viewModel.state == .ready
        }

        viewModel.updateShipments([shipment])

        // Then
        XCTAssertNil(viewModel.paymentMethodLine)
    }

    func test_payment_method_line_is_add_when_no_payment_method_selected() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddress = WooShippingOriginAddress.fake().copy(
            id: "default",
            address1: "Test address line",
            defaultAddress: true
        )
        let shipment = Shipment(
            contents: [],
            purchasedLabel: nil,
            currency: "USD",
            currencySettings: ServiceLocator.currencySettings,
            shippingSettingsService: MockShippingSettingsService()
        )

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadPackages, .verifyDestinationAddress:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(), stores: stores)

        waitUntil {
            viewModel.state == .ready
        }

        viewModel.updateShipments([shipment])

        // Then
        XCTAssertEqual(viewModel.paymentMethodLine, .add)
    }

    func test_payment_method_line_shows_card_when_payment_method_selected() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddress = WooShippingOriginAddress.fake().copy(
            id: "default",
            address1: "Test address line",
            defaultAddress: true
        )

        let paymentMethod = ShippingLabelPaymentMethod.fake().copy(
            paymentMethodID: 11743265,
            name: "Example User",
            cardType: .visa,
            cardDigits: "4242"
        )

        let accountSettings = ShippingLabelAccountSettings.fake().copy(
            paymentMethods: [paymentMethod],
            selectedPaymentMethodID: paymentMethod.paymentMethodID
        )

        let settings = WooShippingAccountSettings(
            storeOptions: ShippingLabelStoreOptions(
                currencySymbol: "$",
                dimensionUnit: "cm",
                weightUnit: "g",
                originCountry: "VN"
            ),
            accountSettings: accountSettings
        )

        let shipment = Shipment(
            contents: [],
            purchasedLabel: nil,
            currency: "USD",
            currencySettings: ServiceLocator.currencySettings,
            shippingSettingsService: MockShippingSettingsService()
        )

        var didLoadAccountSettings = false
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                didLoadAccountSettings = true
                completion(.success(settings))
            case .loadPackages, .verifyDestinationAddress:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(),
                                                         shippingSettingsService: MockShippingSettingsService(dimensionUnit: "", weightUnit: ""),
                                                         stores: stores)

        waitUntil {
            viewModel.state == .ready
        }

        viewModel.updateShipments([shipment])

        // Then
        XCTAssertTrue(didLoadAccountSettings, "Account settings should be loaded")
        if case .card(let cardViewModel) = viewModel.paymentMethodLine {
            XCTAssertEqual(cardViewModel.title, "VISA****4242")
            XCTAssertTrue(cardViewModel.isEditable)
        } else {
            XCTFail("Expected card payment method line")
        }
    }

    func test_didUpdateAccountSettings_updates_paymentMethodLine() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let originAddress = WooShippingOriginAddress.fake().copy(
            id: "default",
            address1: "Test address line",
            defaultAddress: true
        )

        let paymentMethod1 = ShippingLabelPaymentMethod.fake().copy(
            paymentMethodID: 11743265,
            name: "Example User",
            cardType: .visa,
            cardDigits: "4242424242424242"
        )

        let paymentMethod2 = ShippingLabelPaymentMethod.fake().copy(
            paymentMethodID: 123523,
            name: "Example User",
            cardType: .mastercard,
            cardDigits: "5555444444444444"
        )

        let accountSettings = ShippingLabelAccountSettings.fake().copy(
            paymentMethods: [paymentMethod1, paymentMethod2],
            selectedPaymentMethodID: paymentMethod1.paymentMethodID
        )

        let settings = WooShippingAccountSettings(
            storeOptions: ShippingLabelStoreOptions(
                currencySymbol: "$",
                dimensionUnit: "cm",
                weightUnit: "g",
                originCountry: "VN"
            ),
            accountSettings: accountSettings
        )

        let shipment = Shipment(
            contents: [],
            purchasedLabel: nil,
            currency: "USD",
            currencySettings: ServiceLocator.currencySettings,
            shippingSettingsService: MockShippingSettingsService()
        )

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(.success([originAddress]))
            case .loadAccountSettings(_, let completion):
                self.insert(accountSettings: accountSettings)
                completion(.success(settings))
            case .loadPackages, .verifyDestinationAddress:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }


        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake(),
                                                         shippingSettingsService: MockShippingSettingsService(dimensionUnit: "", weightUnit: ""),
                                                         stores: stores)

        waitUntil {
            viewModel.state == .ready
        }

        viewModel.updateShipments([shipment])

        // Confidence check
        XCTAssertEqual(viewModel.paymentMethodLine, WooShippingPaymentMethodLine.card(
            .init(id: paymentMethod1.paymentMethodID,
                  title: "VISA****4242",
                  isEditable: true)
        ))

        // When
        let newSettings = MockShippingLabelAccountSettings.sampleAccountSettings(
            paymentMethods: [paymentMethod1, paymentMethod2],
            selectedPaymentMethodID: paymentMethod2.paymentMethodID
        )
        viewModel.didUpdateAccountSettings(newSettings)

        // Then
        XCTAssertEqual(viewModel.paymentMethodLine, WooShippingPaymentMethodLine.card(
            .init(id: paymentMethod2.paymentMethodID,
                  title: "MASTERCARD****4444",
                  isEditable: true)
        ))
    }

    // MARK: - loadRequiredData with stored data tests

    func test_loadRequiredData_state_becomes_ready_immediately_when_origin_addresses_and_settings_are_stored() {
        // Given
        let originAddress = WooShippingOriginAddress(siteID: siteID,
                                                     id: "stored_address",
                                                     company: "Stored Company",
                                                     address1: "123 Stored St",
                                                     address2: "",
                                                     city: "San Francisco",
                                                     state: "CA",
                                                     postcode: "94102",
                                                     country: "US",
                                                     phone: "555-0123",
                                                     firstName: "John",
                                                     lastName: "Doe",
                                                     email: "john@stored.com",
                                                     defaultAddress: true,
                                                     isVerified: true)

        let accountSettings = ShippingLabelAccountSettings.fake().copy(siteID: siteID)

        // Pre-populate storage with data
        insert(originAddress: originAddress)
        insert(accountSettings: accountSettings)

        let stores = MockStoresManager(sessionManager: .testingInstance)
        let shippingSettingsService = MockShippingSettingsService(dimensionUnit: "cm", weightUnit: "g")
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(siteID: siteID),
                                                         shippingSettingsService: shippingSettingsService,
                                                         stores: stores,
                                                         storageManager: storageManager)

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertEqual(viewModel.originAddress, "123 Stored St, San Francisco CA 94102, US")
        XCTAssertEqual(viewModel.dimensionsUnit, "cm")
        XCTAssertEqual(viewModel.weightUnit, "g")
    }

    func test_loadRequiredData_state_becomes_ready_immediately_when_only_origin_addresses_are_stored() {
        // Given
        let originAddress = WooShippingOriginAddress(siteID: siteID,
                                                     id: "stored_address",
                                                     company: "Stored Company",
                                                     address1: "456 Another St",
                                                     address2: "",
                                                     city: "Los Angeles",
                                                     state: "CA",
                                                     postcode: "90210",
                                                     country: "US",
                                                     phone: "555-0456",
                                                     firstName: "Jane",
                                                     lastName: "Smith",
                                                     email: "jane@stored.com",
                                                     defaultAddress: true,
                                                     isVerified: false)

        // Pre-populate storage with origin addresses only
        insert(originAddress: originAddress)

        let stores = MockStoresManager(sessionManager: .testingInstance)
        var accountSettingsLoaded = false

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadAccountSettings(_, let completion):
                accountSettingsLoaded = true
                completion(.success(self.settings))
            case .loadPackages, .verifyDestinationAddress, .loadOriginAddresses:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let shippingSettingsService = MockShippingSettingsService(dimensionUnit: nil, weightUnit: nil)
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(siteID: siteID),
                                                         shippingSettingsService: shippingSettingsService,
                                                         stores: stores,
                                                         storageManager: storageManager)

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertEqual(viewModel.originAddress, "456 Another St, Los Angeles CA 90210, US")
        XCTAssertTrue(accountSettingsLoaded, "Account settings should be loaded from remote when missing")
        XCTAssertEqual(viewModel.dimensionsUnit, settings.storeOptions.dimensionUnit)
        XCTAssertEqual(viewModel.weightUnit, settings.storeOptions.weightUnit)
    }

    func test_loadRequiredData_state_becomes_ready_immediately_when_only_account_settings_are_stored() {
        // Given
        let accountSettings = ShippingLabelAccountSettings.fake().copy(siteID: siteID)

        // Pre-populate storage with account settings only
        insert(accountSettings: accountSettings)

        let originAddress = WooShippingOriginAddress(siteID: siteID,
                                                     id: "stored_address",
                                                     company: "Stored Company",
                                                     address1: "456 Another St",
                                                     address2: "",
                                                     city: "Los Angeles",
                                                     state: "CA",
                                                     postcode: "90210",
                                                     country: "US",
                                                     phone: "555-0456",
                                                     firstName: "Jane",
                                                     lastName: "Smith",
                                                     email: "jane@stored.com",
                                                     defaultAddress: true,
                                                     isVerified: false)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var originAddressesLoaded = false

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                originAddressesLoaded = true
                completion(.success([originAddress]))
            case .loadPackages, .verifyDestinationAddress, .loadAccountSettings:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let shippingSettingsService = MockShippingSettingsService(dimensionUnit: "cm", weightUnit: "g")
        let viewModel = WooShippingCreateLabelsViewModel(order: Order.fake().copy(siteID: siteID),
                                                         shippingSettingsService: shippingSettingsService,
                                                         stores: stores,
                                                         storageManager: storageManager)

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertTrue(originAddressesLoaded, "Origin addresses should be loaded from remote when missing")
        XCTAssertFalse(viewModel.originAddress.isEmpty, "Origin address should be set from loaded data")
    }

    // MARK: - split shipments feature visibility tests

    private func initialConfigurationForSplitShipmentsTest(stores: MockStoresManager) {
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .verifyDestinationAddress(_, _, let completion):
                completion(
                    .success(
                        WooShippingVerifyDestinationAddressSuccess(
                            normalizedAddress: WooShippingNormalizedAddress.fake(),
                            isTrivialNormalization: nil,
                            isVerified: true
                        )
                    )
                )
            case .loadAccountSettings(_, let completion):
                completion(.success(self.settings))
            case .loadOriginAddresses(_, let completion):
                let originAddress = WooShippingOriginAddress.fake().copy(address1: "123 Main Street", defaultAddress: true)
                completion(.success([originAddress]))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
    }

    func test_splitShipmentsRowVisible_is_false_when_split_shipments_feature_is_unavailable() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        initialConfigurationForSplitShipmentsTest(stores: stores)

        /// Is CIAB site with the `.splitShipments` disabled
        let mockSiteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: true,
            mockedCIABDisabledFeatures: [.splitShipments]
        )

        /// Multiple products
        let product1 = Product.fake().copy(siteID: siteID, productID: 1)
        let product2 = Product.fake().copy(siteID: siteID, productID: 2)

        storageManager.insertSampleProduct(readOnlyProduct: product1)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let order = Order.fake().copy(
            siteID: siteID,
            orderID: orderID,
            items: [
                OrderItem.fake().copy(productID: product1.productID, quantity: 1),
                OrderItem.fake().copy(productID: product2.productID, quantity: 1)
            ])

        /// Single unfulfilled shipment
        let shipments = [
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_0",
                items: [
                    .fake().copy(id: product1.productID),
                    .fake().copy(id: product2.productID)
                ])
        ]
        insert(shipments: shipments, order: order)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            stores: stores,
            storageManager: storageManager,
            siteCIABEligibilityChecker: mockSiteCIABChecker,
            initialNoticeDelay: .seconds(0)
        )

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertFalse(viewModel.splitShipmentsRowVisible)
    }

    func test_splitShipmentsRowVisible_is_false_when_only_single_product_item_exists() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        initialConfigurationForSplitShipmentsTest(stores: stores)

        /// Non-CIAB site
        let mockSiteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: false,
            mockedCIABDisabledFeatures: []
        )

        /// Single product
        let product1 = Product.fake().copy(siteID: siteID, productID: 1)
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let order = Order.fake().copy(
            siteID: siteID,
            orderID: orderID,
            items: [
                OrderItem.fake().copy(productID: product1.productID, quantity: 1)
            ])

        /// Single unfulfilled shipment
        let shipments = [
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_0",
                items: [
                    .fake().copy(id: product1.productID)
                ])
        ]
        insert(shipments: shipments, order: order)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            stores: stores,
            storageManager: storageManager,
            siteCIABEligibilityChecker: mockSiteCIABChecker,
            initialNoticeDelay: .seconds(0)
        )

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertFalse(viewModel.splitShipmentsRowVisible)
    }

    func test_splitShipmentsRowVisible_is_false_when_order_has_multiple_shipments() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        initialConfigurationForSplitShipmentsTest(stores: stores)

        /// Non-CIAB site
        let mockSiteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: false,
            mockedCIABDisabledFeatures: []
        )

        /// Multiple products
        let product1 = Product.fake().copy(siteID: siteID, productID: 1)
        let product2 = Product.fake().copy(siteID: siteID, productID: 2)

        storageManager.insertSampleProduct(readOnlyProduct: product1)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let order = Order.fake().copy(
            siteID: siteID,
            orderID: orderID,
            items: [
                OrderItem.fake().copy(productID: product1.productID, quantity: 1),
                OrderItem.fake().copy(productID: product2.productID, quantity: 1)
            ])

        /// Multiple shipments
        let shipments = [
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_0",
                items: [
                    .fake().copy(id: product1.productID)
                ]),
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_1",
                items: [
                    .fake().copy(id: product2.productID)
                ])
        ]
        insert(shipments: shipments, order: order)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            stores: stores,
            storageManager: storageManager,
            siteCIABEligibilityChecker: mockSiteCIABChecker,
            initialNoticeDelay: .seconds(0)
        )

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertFalse(viewModel.splitShipmentsRowVisible)
    }

    func test_splitShipmentsRowVisible_is_true_when_requirements_met() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        initialConfigurationForSplitShipmentsTest(stores: stores)

        /// Non-CIAB site (feature available)
        let mockSiteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: false,
            mockedCIABDisabledFeatures: []
        )

        /// Multiple products
        let product1 = Product.fake().copy(siteID: siteID, productID: 1)
        let product2 = Product.fake().copy(siteID: siteID, productID: 2)

        storageManager.insertSampleProduct(readOnlyProduct: product1)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let order = Order.fake().copy(
            siteID: siteID,
            orderID: orderID,
            items: [
                OrderItem.fake().copy(productID: product1.productID, quantity: 1),
                OrderItem.fake().copy(productID: product2.productID, quantity: 1)
            ])

        /// Single unfulfilled shipment
        let shipments = [
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_0",
                items: [
                    .fake().copy(id: product1.productID),
                    .fake().copy(id: product2.productID)
                ])
        ]
        insert(shipments: shipments, order: order)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            stores: stores,
            storageManager: storageManager,
            siteCIABEligibilityChecker: mockSiteCIABChecker,
            initialNoticeDelay: .seconds(0)
        )

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertTrue(viewModel.splitShipmentsRowVisible)
    }

    func test_editSplitShipmentsOptionVisible_is_false_when_split_shipments_feature_is_unavailable() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        initialConfigurationForSplitShipmentsTest(stores: stores)

        /// Is CIAB site with the `.splitShipments` disabled
        let mockSiteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: true,
            mockedCIABDisabledFeatures: [.splitShipments]
        )

        /// Multiple products
        let product1 = Product.fake().copy(siteID: siteID, productID: 1)
        let product2 = Product.fake().copy(siteID: siteID, productID: 2)

        storageManager.insertSampleProduct(readOnlyProduct: product1)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let order = Order.fake().copy(
            siteID: siteID,
            orderID: orderID,
            items: [
                OrderItem.fake().copy(productID: product1.productID, quantity: 1),
                OrderItem.fake().copy(productID: product2.productID, quantity: 1)
            ])

        /// Single unfulfilled shipment
        let shipments = [
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_0",
                items: [
                    .fake().copy(id: product1.productID),
                    .fake().copy(id: product2.productID)
                ])
        ]
        insert(shipments: shipments, order: order)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            stores: stores,
            storageManager: storageManager,
            siteCIABEligibilityChecker: mockSiteCIABChecker,
            initialNoticeDelay: .seconds(0)
        )

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertFalse(viewModel.editSplitShipmentsOptionVisible)
    }

    func test_editSplitShipmentsOptionVisible_is_false_when_only_single_product_item_exists() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        initialConfigurationForSplitShipmentsTest(stores: stores)

        /// Non-CIAB site (split shipments available)
        let mockSiteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: false,
            mockedCIABDisabledFeatures: []
        )

        /// Single product
        let product1 = Product.fake().copy(siteID: siteID, productID: 1)
        storageManager.insertSampleProduct(readOnlyProduct: product1)

        let order = Order.fake().copy(
            siteID: siteID,
            orderID: orderID,
            items: [
                OrderItem.fake().copy(productID: product1.productID, quantity: 1)
            ])

        /// Single unfulfilled shipment
        let shipments = [
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_0",
                items: [
                    .fake().copy(id: product1.productID)
                ])
        ]
        insert(shipments: shipments, order: order)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            stores: stores,
            storageManager: storageManager,
            siteCIABEligibilityChecker: mockSiteCIABChecker,
            initialNoticeDelay: .seconds(0)
        )

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertFalse(viewModel.editSplitShipmentsOptionVisible)
    }

    func test_editSplitShipmentsOptionVisible_is_false_when_all_shipments_fulfilled() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        initialConfigurationForSplitShipmentsTest(stores: stores)

        /// Non-CIAB site (split shipments available)
        let mockSiteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: false,
            mockedCIABDisabledFeatures: []
        )

        /// Multiple products
        let product1 = Product.fake().copy(siteID: siteID, productID: 1)
        let product2 = Product.fake().copy(siteID: siteID, productID: 2)

        storageManager.insertSampleProduct(readOnlyProduct: product1)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let order = Order.fake().copy(
            siteID: siteID,
            orderID: orderID,
            items: [
                OrderItem.fake().copy(productID: product1.productID, quantity: 1),
                OrderItem.fake().copy(productID: product2.productID, quantity: 1)
            ])

        /// Each shipment is fulfilled
        let shippingLabel1 = ShippingLabel.fake().copy(siteID: siteID, orderID: orderID, shippingLabelID: 134)
        let shippingLabel2 = ShippingLabel.fake().copy(siteID: siteID, orderID: orderID, shippingLabelID: 245)

        /// 2 fulfilled shipments
        let shipments = [
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_0",
                items: [
                    .fake().copy(id: product1.productID)
                ],
                shippingLabel: shippingLabel1
            ),
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_1",
                items: [
                    .fake().copy(id: product2.productID)
                ],
                shippingLabel: shippingLabel2
            )
        ]
        insert(shipments: shipments, order: order)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            stores: stores,
            storageManager: storageManager,
            siteCIABEligibilityChecker: mockSiteCIABChecker,
            initialNoticeDelay: .seconds(0)
        )

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertFalse(viewModel.editSplitShipmentsOptionVisible)
    }

    func test_editSplitShipmentsOptionVisible_is_true_when_all_requirements_met() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        initialConfigurationForSplitShipmentsTest(stores: stores)

        /// Non-CIAB site (split shipments available)
        let mockSiteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: false,
            mockedCIABDisabledFeatures: []
        )

        /// Multiple products
        let product1 = Product.fake().copy(siteID: siteID, productID: 1)
        let product2 = Product.fake().copy(siteID: siteID, productID: 2)

        storageManager.insertSampleProduct(readOnlyProduct: product1)
        storageManager.insertSampleProduct(readOnlyProduct: product2)

        let order = Order.fake().copy(
            siteID: siteID,
            orderID: orderID,
            items: [
                OrderItem.fake().copy(productID: product1.productID, quantity: 1),
                OrderItem.fake().copy(productID: product2.productID, quantity: 1)
            ])

        /// Single unfulfilled shipment
        let shipments = [
            WooShippingShipment.fake().copy(
                siteID: siteID,
                orderID: orderID,
                index: "shipment_0",
                items: [
                    .fake().copy(id: product1.productID),
                    .fake().copy(id: product2.productID)
                ])
        ]
        insert(shipments: shipments, order: order)

        // When
        let viewModel = WooShippingCreateLabelsViewModel(
            order: order,
            stores: stores,
            storageManager: storageManager,
            siteCIABEligibilityChecker: mockSiteCIABChecker,
            initialNoticeDelay: .seconds(0)
        )

        waitUntil {
            viewModel.state == .ready
        }

        // Then
        XCTAssertTrue(viewModel.editSplitShipmentsOptionVisible)
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

    func setupInitialDataLoadingMocks(
        for stores: MockStoresManager,
        originAddressesResult: Result<[WooShippingOriginAddress], Error> = .success([.fake().copy(id: "default", defaultAddress: true)]),
        accountSettingsResult: Result<WooShippingAccountSettings, Error> = .success(.fake())
    ) {
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case .loadOriginAddresses(_, let completion):
                completion(originAddressesResult)
            case .loadAccountSettings(_, let completion):
                completion(accountSettingsResult)
            case .loadPackages, .verifyDestinationAddress:
                break // Ignored for these tests
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
    }

    func insert(shipments: [WooShippingShipment], order: Order) {
        let storageOrder = storage.insertNewObject(ofType: StorageOrder.self)
        storageOrder.update(with: order)

        for shipment in shipments {
            let storageShipment = storage.insertNewObject(ofType: StorageWooShippingShipment.self)
            storageShipment.update(with: shipment)
            storageShipment.order = storageOrder

            if let shippingLabel = shipment.shippingLabel {
                let storageShippingLabel = storage.insertNewObject(ofType: StorageShippingLabel.self)
                storageShippingLabel.update(with: shippingLabel)
                if let shippingLabelRefund = shippingLabel.refund {
                    let storageRefund = storage.insertNewObject(ofType: StorageShippingLabelRefund.self)
                    storageRefund.update(with: shippingLabelRefund)
                    storageShippingLabel.refund = storageRefund
                }
                storageShippingLabel.order = storageOrder
                storageShippingLabel.shipment = storageShipment

                let originAddress = storage.insertNewObject(ofType: StorageShippingLabelAddress.self)
                originAddress.update(with: shippingLabel.originAddress)
                storageShippingLabel.originAddress = originAddress

                let destinationAddress = storage.insertNewObject(ofType: StorageShippingLabelAddress.self)
                destinationAddress.update(with: shippingLabel.destinationAddress)
                storageShippingLabel.destinationAddress = destinationAddress
            }
        }
    }

    func insert(originAddress: WooShippingOriginAddress) {
        let storageAddress = storage.insertNewObject(ofType: StorageWooShippingOriginAddress.self)
        storageAddress.update(with: originAddress)

    }

    func insert(accountSettings: ShippingLabelAccountSettings) {
        let storageSettings = storage.insertNewObject(ofType: StorageShippingLabelAccountSettings.self)
        storageSettings.update(with: accountSettings)
    }
}

private extension WooShippingAccountSettings {
    static func fake() -> WooShippingAccountSettings {
        .init(storeOptions: .init(currencySymbol: "$", dimensionUnit: "in", weightUnit: "lbs", originCountry: "US"),
              accountSettings: .fake())
    }
}
