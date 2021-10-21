import XCTest
import Yosemite
import TestKit
import Combine
@testable import WooCommerce

final class EditOrderAddressFormViewModelTests: XCTestCase {

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
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: address), type: .shipping, storageManager: testingStorage)

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
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: address), type: .shipping, storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.fields.firstName = "John"

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_updating_fields_back_to_original_values_disables_done_button() {
        // Given
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, storageManager: testingStorage)
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
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: nil), type: .shipping, storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_creating_with_address_with_empty_nullable_fields_disables_done_button() {
        // Given
        let address = sampleAddressWithEmptyNullableFields()
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: address), type: .shipping, storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_turning_on_use_as_toggle_enables_done_button() {
        // Given
        let address = sampleAddress()
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: address), type: .shipping, storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.fields.useAsToggle = true

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_turning_off_use_as_toggle_disables_done_button() {
        // Given
        let address = sampleAddress()
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: address), type: .shipping, storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.fields.useAsToggle = true
        viewModel.fields.useAsToggle = false

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_turning_off_use_as_toggle_does_not_disable_done_button_when_address_is_edited() {
        // Given
        let address = sampleAddress()
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: address), type: .shipping, storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.fields.useAsToggle = true
        viewModel.fields.firstName = "John"
        viewModel.fields.useAsToggle = false

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_loading_indicator_gets_enabled_during_network_request() {
        // Given
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()
        viewModel.updateRemoteAddress { _ in }

        // Then
        assertEqual(viewModel.navigationTrailingItem, .loading)
    }

    func test_loading_indicator_gets_disabled_after_the_network_operation_completes() {
        // Given
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, storageManager: testingStorage)

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
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: sampleAddress()),
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

        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: sampleAddress()),
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

        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, storageManager: testingStorage)
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
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, stores: stores)

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

    func test_view_model_updates_shipping_and_billing_address_fields_when_use_as_toggle_is_on() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, stores: stores)

        // When
        viewModel.fields.firstName = "Tester"
        viewModel.fields.useAsToggle = true

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
        assertEqual(update.order.billingAddress?.firstName, "Tester")
        assertEqual(update.fields, [.shippingAddress, .billingAddress])
    }

    func test_view_model_only_updates_billing_address_field() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditOrderAddressFormViewModel(order: order(withBillingAddress: sampleAddress()), type: .billing, stores: stores)

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

        let viewModel = EditOrderAddressFormViewModel(order: order(withShippingAddress: sampleAddress()), type: .shipping, storageManager: testingStorage)
        viewModel.onLoadTrigger.send()

        // When
        let stateViewModel = viewModel.createStateViewModel()
        let viewController = ListSelectorViewController(command: stateViewModel.command, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        stateViewModel.command.handleSelectedChange(selected: newState, viewController: viewController)

        // Then
        XCTAssertEqual(viewModel.fields.state, newState.name)
    }

    func test_view_model_updates_billing_and_shipping_address_fields_when_use_as_toggle_is_on() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditOrderAddressFormViewModel(order: order(withBillingAddress: sampleAddress()), type: .billing, stores: stores)

        // When
        viewModel.fields.firstName = "Tester"
        viewModel.fields.useAsToggle = true

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
        assertEqual(update.order.shippingAddress?.firstName, "Tester")
        assertEqual(update.fields, [.billingAddress, .shippingAddress])
    }

    func test_view_model_fires_success_notice_after_updating_address_successfully() {
        // Given
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .shipping, stores: testingStores)
        testingStores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, order, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        let noticeRequest = waitFor { promise in
            viewModel.updateRemoteAddress { _ in
                promise(viewModel.presentNotice)
            }
        }

        // Then
        assertEqual(noticeRequest, .success)
    }

    func test_view_model_fires_error_notice_after_failing_to_update_address() {
        // Given
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .shipping, stores: testingStores)
        testingStores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "", code: 0)))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        let noticeRequest = waitFor { promise in
            viewModel.updateRemoteAddress { _ in
                promise(viewModel.presentNotice)
            }
        }

        // Then
        assertEqual(noticeRequest, .error(.unableToUpdateAddress))
    }

    func test_view_model_fires_error_notice_after_failing_to_fetch_countries() {
        // Given
        testingStorage.reset()
        testingStores.whenReceivingAction(ofType: DataAction.self) { action in
            switch action {
            case .synchronizeCountries(_, let completion):
                completion(.failure(NSError(domain: "", code: 0)))
            }
        }

        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .shipping, storageManager: testingStorage, stores: testingStores)
        viewModel.onLoadTrigger.send()

        // Then
        assertEqual(viewModel.presentNotice, .error(.unableToLoadCountries))
    }

    func test_copying_empty_shipping_address_for_billing_does_not_sends_an_empty_email_field() {
        // Given
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .shipping, storageManager: testingStorage, stores: testingStores)
        viewModel.onLoadTrigger.send()
        viewModel.fields.useAsToggle = true

        // When
        let billingAddress: Address? = waitFor { promise in
            self.testingStores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .updateOrder(_, order, _, _):
                    promise(order.billingAddress)
                default:
                    XCTFail("Unsupported Action")
                }
            }

            viewModel.updateRemoteAddress(onFinish: { _ in })
        }

        // Then
        XCTAssertNil(billingAddress?.email)
    }

    func test_shipping_view_model_does_not_shows_email_field() {
        // Given
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .shipping)

        // When & Then
        XCTAssertFalse(viewModel.showEmailField)
    }

    func test_billing_view_model_does_shows_email_field() {
        // Given
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .billing)

        // When & Then
        XCTAssertTrue(viewModel.showEmailField)
    }

    func test_view_model_tracks_success_after_updating_shipping_address() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(),
                                                 type: .shipping,
                                                 stores: testingStores,
                                                 analytics: WooAnalytics(analyticsProvider: analyticsProvider))
        testingStores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, order, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        _ = waitFor { promise in
            viewModel.updateRemoteAddress(onFinish: { finished in
                promise(finished)
            })
        }

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowCompleted.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "shipping_address")
    }

    func test_view_model_tracks_success_after_updating_billing_address() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(),
                                                 type: .billing,
                                                 stores: testingStores,
                                                 analytics: WooAnalytics(analyticsProvider: analyticsProvider))
        testingStores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, order, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        _ = waitFor { promise in
            viewModel.updateRemoteAddress(onFinish: { finished in
                promise(finished)
            })
        }

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowCompleted.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "billing_address")
    }

    func test_view_model_tracks_failure_after_updating_shipping_address() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(),
                                                 type: .shipping,
                                                 stores: testingStores,
                                                 analytics: WooAnalytics(analyticsProvider: analyticsProvider))
        testingStores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "", code: 0)))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        _ = waitFor { promise in
            viewModel.updateRemoteAddress(onFinish: { finished in
                promise(finished)
            })
        }

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowFailed.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "shipping_address")
    }

    func test_view_model_tracks_failure_after_updating_billing_address() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(),
                                                 type: .billing,
                                                 stores: testingStores,
                                                 analytics: WooAnalytics(analyticsProvider: analyticsProvider))
        testingStores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "", code: 0)))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        _ = waitFor { promise in
            viewModel.updateRemoteAddress(onFinish: { finished in
                promise(finished)
            })
        }

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowFailed.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "billing_address")
    }

    func test_view_model_tracks_cancel_flow_for_shipping_address() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .shipping, analytics: WooAnalytics(analyticsProvider: analyticsProvider))

        // When
        viewModel.userDidCancelFlow()

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowCanceled.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "shipping_address")
    }

    func test_view_model_tracks_cancel_flow_for_billing_address() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .billing, analytics: WooAnalytics(analyticsProvider: analyticsProvider))

        // When
        viewModel.userDidCancelFlow()

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowCanceled.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "billing_address")
    }

    func test_view_model_tracks_started_flow_for_shipping_address() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .shipping, analytics: WooAnalytics(analyticsProvider: analyticsProvider))

        // When
        viewModel.onLoadTrigger.send()

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowStarted.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "shipping_address")
    }

    func test_view_model_tracks_started_flow_for_billing_address() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditOrderAddressFormViewModel(order: Order.fake(), type: .billing, analytics: WooAnalytics(analyticsProvider: analyticsProvider))

        // When
        viewModel.onLoadTrigger.send()

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowStarted.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "billing_address")
    }
}

private extension EditOrderAddressFormViewModelTests {
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

private extension EditOrderAddressFormViewModelTests {
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
