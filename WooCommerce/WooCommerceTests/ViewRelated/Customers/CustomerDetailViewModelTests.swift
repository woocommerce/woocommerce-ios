import XCTest
import Yosemite
@testable import WooCommerce
import WooFoundation

final class CustomerDetailViewModelTests: XCTestCase {

    private let dateFormatter = DateFormatter.mediumLengthLocalizedDateFormatter

    func test_it_inits_with_expected_values_from_customer() throws {
        // Given
        let customer = sampleCustomer()

        // When
        let vm = CustomerDetailViewModel(customer: customer, currencySettings: CurrencySettings())

        // Then
        assertEqual(customer.name, vm.name)
        assertEqual(customer.email, vm.email)
        assertEqual(dateFormatter.string(from: try XCTUnwrap(customer.dateRegistered)), vm.dateRegistered)
        assertEqual(dateFormatter.string(from: try XCTUnwrap(customer.dateLastActive)), vm.dateLastActive)
        assertEqual(customer.ordersCount.description, vm.ordersCount)
        assertEqual("$10.00", vm.totalSpend)
        assertEqual("$5.00", vm.avgOrderValue)
        assertEqual(customer.country, vm.country)
        assertEqual(customer.region, vm.region)
        assertEqual(customer.city, vm.city)
        assertEqual(customer.postcode, vm.postcode)
        XCTAssertTrue(vm.showLocation)
    }

    func test_it_inits_with_expected_values_from_empty_customer() {
        // Given
        let customer = WCAnalyticsCustomer.fake().copy(name: " ",
                                                       email: "",
                                                       username: "",
                                                       dateRegistered: .some(nil),
                                                       dateLastActive: .some(nil),
                                                       ordersCount: 0,
                                                       totalSpend: 0,
                                                       averageOrderValue: 0,
                                                       country: "",
                                                       region: "",
                                                       city: "",
                                                       postcode: "")

        // When
        let vm = CustomerDetailViewModel(customer: customer, currencySettings: CurrencySettings())

        // Then
        assertEqual("Guest", vm.name)
        assertEqual(customer.ordersCount.description, vm.ordersCount)
        assertEqual("$0.00", vm.totalSpend)
        assertEqual("$0.00", vm.avgOrderValue)
        XCTAssertNil(vm.email)
        XCTAssertNil(vm.dateRegistered)
        XCTAssertNil(vm.dateLastActive)
        XCTAssertNil(vm.country)
        XCTAssertNil(vm.region)
        XCTAssertNil(vm.city)
        XCTAssertNil(vm.postcode)
        XCTAssertTrue(vm.showLocation)
    }

    func test_it_updates_billing_and_shipping_and_phone_from_remote() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let vm = CustomerDetailViewModel(customer: sampleCustomer(), stores: stores, storageManager: storage)
        let billing = sampleAddress()
        let shipping = Address.fake().copy(company: "Widget Shop", address1: "1 Main Street")

        // When
        _ = waitFor { promise in
            stores.whenReceivingAction(ofType: CustomerAction.self) { action in
                switch action {
                case let .retrieveCustomer(_, customerID, onCompletion):
                    let customer = Customer.fake().copy(customerID: customerID, billing: billing, shipping: shipping)
                    storage.insertSampleCustomer(readOnlyCustomer: customer)
                    onCompletion(.success(customer))
                    promise(true)
                default:
                    XCTFail("Received unexpected action")
                }
            }
            vm.syncCustomerAddressData()
        }

        // Then
        let viewModel = try XCTUnwrap(vm)
        XCTAssertFalse(viewModel.showLocation)
        assertEqual(billing.fullNameWithCompanyAndAddress, viewModel.formattedBilling)
        assertEqual(shipping.fullNameWithCompanyAndAddress, viewModel.formattedShipping)
        assertEqual(billing.phone, viewModel.phone)
    }

    func test_it_updates_isSyncing_during_and_after_sync() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let vm = CustomerDetailViewModel(customer: sampleCustomer(), stores: stores)
        let isSyncingOnInit = vm.isSyncing

        // When
        let isSyncingDuringAction: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: CustomerAction.self) { action in
                switch action {
                case let .retrieveCustomer(_, customerID, onCompletion):
                    let customer = Customer.fake().copy(customerID: customerID, billing: Address.fake())
                    promise(vm.isSyncing)
                    onCompletion(.success(customer))
                default:
                    XCTFail("Received unexpected action")
                }
            }
            vm.syncCustomerAddressData()
        }

        // Then
        XCTAssertFalse(isSyncingOnInit)
        XCTAssertTrue(isSyncingDuringAction)
        XCTAssertFalse(vm.isSyncing)
    }

    func test_isSyncing_not_true_if_data_already_loaded() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let customer = Customer.fake().copy(customerID: sampleCustomer().userID, billing: Address.fake())
        storage.insertSampleCustomer(readOnlyCustomer: customer)
        let vm = CustomerDetailViewModel(customer: sampleCustomer(), stores: stores, storageManager: storage)
        let isSyncingOnInit = vm.isSyncing

        // When
        let isSyncingDuringAction: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: CustomerAction.self) { action in
                switch action {
                case let .retrieveCustomer(_, _, onCompletion):
                    promise(vm.isSyncing)
                    onCompletion(.success(customer))
                default:
                    XCTFail("Received unexpected action")
                }
            }
            vm.syncCustomerAddressData()
        }

        // Then
        XCTAssertFalse(isSyncingOnInit)
        XCTAssertFalse(isSyncingDuringAction)
        XCTAssertFalse(vm.isSyncing)
    }

    func test_it_fetches_billing_and_shipping_from_storage() {
        // Given
        let billing = sampleAddress()
        let shipping = Address.fake().copy(company: "Widget Shop", address1: "1 Main Street")
        let customer = Customer.fake().copy(customerID: sampleCustomer().userID, billing: billing, shipping: shipping)
        let storage = MockStorageManager()
        storage.insertSampleCustomer(readOnlyCustomer: customer)

        // When
        let vm = CustomerDetailViewModel(customer: sampleCustomer(), storageManager: storage)

        // Then
        assertEqual(billing.fullNameWithCompanyAndAddress, vm.formattedBilling)
        assertEqual(shipping.fullNameWithCompanyAndAddress, vm.formattedShipping)
        assertEqual(billing.phone, vm.phone)
    }

}

private extension CustomerDetailViewModelTests {
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

    func sampleCustomer() -> WCAnalyticsCustomer {
        WCAnalyticsCustomer.fake().copy(userID: 123,
                                        name: "Pat Smith",
                                        email: "pat.smith@example.com",
                                        username: "psmith",
                                        dateRegistered: Date(),
                                        dateLastActive: Date(),
                                        ordersCount: 2,
                                        totalSpend: 10,
                                        averageOrderValue: 5,
                                        country: "US",
                                        region: "CA",
                                        city: "San Francisco",
                                        postcode: "94103")
    }
}
