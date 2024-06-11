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
        assertEqual(dateFormatter.string(from: customer.dateLastActive), vm.dateLastActive)
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
                                                       dateLastActive: Date(),
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
        assertEqual(dateFormatter.string(from: customer.dateLastActive), vm.dateLastActive)
        assertEqual(customer.ordersCount.description, vm.ordersCount)
        assertEqual("$0.00", vm.totalSpend)
        assertEqual("$0.00", vm.avgOrderValue)
        XCTAssertNil(vm.email)
        XCTAssertNil(vm.dateRegistered)
        XCTAssertNil(vm.country)
        XCTAssertNil(vm.region)
        XCTAssertNil(vm.city)
        XCTAssertNil(vm.postcode)
        XCTAssertTrue(vm.showLocation)
    }

    func test_it_updates_billing_and_shipping_and_phone_from_remote() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let billing = sampleAddress()
        let shipping = Address.fake().copy(company: "Widget Shop", address1: "1 Main Street")

        // When
        var vm: CustomerDetailViewModel?
        _ = waitFor { promise in
            stores.whenReceivingAction(ofType: CustomerAction.self) { action in
                switch action {
                case let .retrieveCustomer(_, userID, onCompletion):
                    let customer = Customer.fake().copy(customerID: userID, billing: billing, shipping: shipping)
                    onCompletion(.success(customer))
                    promise(true)
                default:
                    XCTFail("Received unexpected action")
                }
            }

            vm = CustomerDetailViewModel(customer: self.sampleCustomer(), stores: stores)
        }

        // Then
        let viewModel = try XCTUnwrap(vm)
        XCTAssertFalse(viewModel.showLocation)
        assertEqual(billing.fullNameWithCompanyAndAddress, viewModel.billing)
        assertEqual(shipping.fullNameWithCompanyAndAddress, viewModel.shipping)
        assertEqual(billing.phone, viewModel.phone)
    }

    func test_it_updates_syncState_after_sync_completes() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let customer = sampleCustomer()

        // When
        var vm: CustomerDetailViewModel?
        _ = waitFor { promise in
            stores.whenReceivingAction(ofType: CustomerAction.self) { action in
                switch action {
                case let .retrieveCustomer(_, userID, onCompletion):
                    let customer = Customer.fake().copy(customerID: customer.customerID, billing: Address.fake())
                    onCompletion(.success(customer))
                    promise(true)
                default:
                    XCTFail("Received unexpected action")
                }
            }

            vm = CustomerDetailViewModel(customer: customer, stores: stores)
        }

        // Then
        let viewModel = try XCTUnwrap(vm)
        XCTAssertFalse(viewModel.isSyncing)
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
