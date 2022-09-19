import XCTest
@testable import Networking

class CustomerMapperTests: XCTestCase {

    func test_data_is_mapped() {
        let mapper = CustomerMapper(siteID: 123)
        guard let data = Loader.contentsOf("customer") else {
            XCTFail("customer.json not found")
            return
        }
        let customer = try? mapper.map(response: data)
        XCTAssertNotNil(mapper)
        XCTAssertNotNil(customer)
        XCTAssertEqual(customer?.customerID, 25)
    }
}

private extension CustomerMapperTests {
    func mapCustomer(from filename: String) throws -> Customer {
        return Customer(
            customerID: 25,
            email: "",
            firstName: "",
            lastName: ""
        )
    }
}
