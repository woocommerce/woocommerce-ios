import XCTest
import Yosemite
import TestKit
import Combine
@testable import WooCommerce

final class EditAddressFormViewModelTests: XCTestCase {

    let sampleSiteID: Int64 = 123

    let testingStorage = MockStorageManager()

    let testingStores = MockStoresManager(sessionManager: .testingInstance)

    var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        testingStorage.reset()
        testingStorage.insertSampleCountries(readOnlyCountries: Self.sampleCountries)

        testingStores.reset()
        subscriptions.removeAll()
    }

    func test_creating_with_address_prefills_fields_with_correct_data() {
        // Given
        let address = sampleAddress()
        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: address), type: .shipping, storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(viewModel.fields.firstName, address.firstName)
        XCTAssertEqual(viewModel.fields.lastName, address.lastName)
        XCTAssertEqual(viewModel.fields.email, address.email ?? "")
        XCTAssertEqual(viewModel.fields.phone, address.phone ?? "")

        XCTAssertEqual(viewModel.fields.company, address.company ?? "")
        XCTAssertEqual(viewModel.fields.address1, address.address1)
        XCTAssertEqual(viewModel.fields.address2, address.address2 ?? "")
        XCTAssertEqual(viewModel.fields.city, address.city)
        XCTAssertEqual(viewModel.fields.postcode, address.postcode)

        let country = Self.sampleCountries.first { $0.code == address.country }
        XCTAssertEqual(viewModel.fields.country, country?.name)
        XCTAssertEqual(viewModel.fields.state, country?.states.first?.name) // Only one state supported in tests

        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_updating_fields_enables_done_button() {
        // Given
        let address = sampleAddress()
        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: address), type: .shipping, storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.fields.firstName = "John"

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_updating_fields_back_to_original_values_disables_done_button() {
        // Given
        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.fields.firstName = "John"
        viewModel.fields.lastName = "Ipsum"
        viewModel.fields.firstName = "Johnny"
        viewModel.fields.lastName = "Appleseed"

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_creating_without_address_disables_done_button() {
        // Given
        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: nil), type: .shipping, storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_creating_with_address_with_empty_nullable_fields_disables_done_button() {
        // Given
        let address = sampleAddressWithEmptyNullableFields()
        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: address), type: .shipping, storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_loading_indicator_gets_enabled_during_network_request() {
        // Given
        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()
        viewModel.updateRemoteAddress { _ in }

        // Then
        assertEqual(viewModel.navigationTrailingItem, .loading)
    }

    func test_loading_indicator_gets_disabled_after_the_network_operation_completes() {
        // Given
        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()
        let navigationItem = waitFor { promise in
            viewModel.updateRemoteAddress { _ in
                promise(viewModel.navigationTrailingItem)
            }
        }

        // Then
        assertEqual(navigationItem, .done(enabled: false))
    }

    func test_starting_view_model_without_stored_countries_fetches_them_remotely() {
        // Given
        testingStorage.reset()
        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: sampleAddress()),
                                                 type: .shipping,
                                                 storageManager: testingStorage,
                                                 stores: testingStores)

        // When
        let countriesFetched: Bool = waitFor { promise in
            self.testingStores.whenReceivingAction(ofType: DataAction.self) { action in
                switch action {
                case .synchronizeCountries:
                    promise(true)
                }
            }

            viewModel.onLoadTrigger.send()
        }

        // Then
        XCTAssertTrue(countriesFetched)
    }

    func test_syncing_countries_correctly_sets_showPlaceholders_properties() {
        // Given
        testingStorage.reset()
        testingStores.whenReceivingAction(ofType: DataAction.self) { action in
            switch action {
            case .synchronizeCountries(_, let completion):
                completion(.success([])) // Sending an empty because we don't really care about countries on this test.
            }
        }

        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: sampleAddress()),
                                                 type: .shipping,
                                                 storageManager: testingStorage,
                                                 stores: testingStores)

        // When
        let showPlaceholdersStates: [Bool] = waitFor { promise in
            viewModel.$showPlaceholders
                .dropFirst() // Drop initial value
                .collect(2)  // Expect two state changes
                .sink { emittedValues in
                    promise(emittedValues)
                }
                .store(in: &self.subscriptions)

            viewModel.onLoadTrigger.send()
        }

        // Then
        assertEqual(showPlaceholdersStates, [true, false]) // true: showPlaceholders, false: hide placeholders
    }

    func test_selecting_country_updates_country_field() {
        // Given
        let newCountry = Self.sampleCountries[0]

        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, storageManager: testingStorage)
        viewModel.onLoadTrigger.send()

        // When
        let countryViewModel = viewModel.createCountryViewModel()
        let viewController = ListSelectorViewController(command: countryViewModel.command, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        countryViewModel.command.handleSelectedChange(selected: newCountry, viewController: viewController)

        // Then
        XCTAssertEqual(viewModel.fields.country, newCountry.name)
    }

    func test_view_model_only_updates_shipping_address_field() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, stores: stores)

        // When
        viewModel.fields.firstName = "Tester"
        let update: (order: Order, fields: [OrderUpdateField]) = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .updateOrder(_, order, fields, _):
                    promise((order, fields))
                default:
                    XCTFail("Unsupported Action")
                }
            }
            viewModel.updateRemoteAddress { _ in }
        }

        // Then
        assertEqual(update.order.shippingAddress?.firstName, "Tester")
        assertEqual(update.fields, [.shippingAddress])
    }

    func test_view_model_only_updates_billing_address_field() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditAddressFormViewModel(order: order(withBillingAddress: sampleAddress()), type: .billing, stores: stores)

        // When
        viewModel.fields.firstName = "Tester"
        let update: (order: Order, fields: [OrderUpdateField]) = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .updateOrder(_, order, fields, _):
                    promise((order, fields))
                default:
                    XCTFail("Unsupported Action")
                }
            }
            viewModel.updateRemoteAddress { _ in }
        }

        // Then
        assertEqual(update.order.billingAddress?.firstName, "Tester")
        assertEqual(update.fields, [.billingAddress])
    }

    func test_selecting_state_updates_state_field() {
        // Given
        let newState = StateOfACountry(code: "CA", name: "California")

        let viewModel = EditAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), storageManager: testingStorage)
        viewModel.onLoadTrigger.send()

        // When
        let stateViewModel = viewModel.createStateViewModel()
        let viewController = ListSelectorViewController(command: stateViewModel.command, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        stateViewModel.command.handleSelectedChange(selected: newState, viewController: viewController)

        // Then
        XCTAssertEqual(viewModel.fields.state, newState.name)
    }
}

private extension EditAddressFormViewModelTests {
    func order(withShippingAddress shippingAddress: Address?) -> Order {
        Order.fake().copy(siteID: 123, orderID: 1234, shippingAddress: shippingAddress)
    }

    func order(withBillingAddress billingAddress: Address?) -> Order {
        Order.fake().copy(siteID: 123, orderID: 1234, billingAddress: billingAddress)
    }

    func sampleAddress() -> Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: nil,
                       address1: "234 70th Street",
                       address2: nil,
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "scrambled@scrambled.com")
    }

    func sampleAddressWithEmptyNullableFields() -> Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: "",
                       address1: "234 70th Street",
                       address2: "",
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "",
                       email: "")
    }
}

private extension EditAddressFormViewModelTests {
    static let sampleCountries: [Country] = {
        return Locale.isoRegionCodes.map { regionCode in
            let name = Locale.current.localizedString(forRegionCode: regionCode) ?? ""
            let states = regionCode == "US" ? [StateOfACountry(code: "NY", name: "New York")] : []
            return Country(code: regionCode, name: name, states: states)
        }.sorted { a, b in
            a.name <= b.name
        }
    }()
}
