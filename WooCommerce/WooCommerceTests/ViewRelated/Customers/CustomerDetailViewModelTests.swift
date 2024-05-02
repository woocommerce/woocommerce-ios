import XCTest
import Yosemite
@testable import WooCommerce
import WooFoundation

final class CustomerDetailViewModelTests: XCTestCase {

    private let dateFormatter = DateFormatter.mediumLengthLocalizedDateFormatter

    func test_it_inits_with_expected_values_from_customer() throws {
        // Given
        let customer = WCAnalyticsCustomer.fake().copy(name: "Pat Smith",
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
    }

}
