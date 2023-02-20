import Networking
import XCTest
import Yosemite
@testable import WooCommerce

final class DomainContactInfoFormViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    func test_init_with_contact_info_pre_fills_all_fields() throws {
        // Given
        let viewModel = DomainContactInfoFormViewModel(siteID: 134,
                                                       contactInfoToEdit: Fixtures.contactInfo,
                                                       domain: "woo.com",
                                                       source: .settings,
                                                       storageManager: ServiceLocator.storageManager,
                                                       stores: ServiceLocator.stores,
                                                       analytics: ServiceLocator.analytics)

        // Then
        XCTAssertEqual(viewModel.fields.firstName, "Woo")
        XCTAssertEqual(viewModel.fields.lastName, "Testing")
        XCTAssertEqual(viewModel.fields.company, "WooCommerce org")
        XCTAssertEqual(viewModel.fields.address1, "335 2nd St")
        XCTAssertEqual(viewModel.fields.address2, "Apt 222")
        XCTAssertEqual(viewModel.fields.postcode, "94111")
        XCTAssertEqual(viewModel.fields.city, "San Francisco")
        XCTAssertEqual(viewModel.fields.state, "CA")
        XCTAssertEqual(viewModel.fields.country, "US")
        XCTAssertEqual(viewModel.fields.phoneCountryCode, "886")
        XCTAssertEqual(viewModel.fields.phone, "911123456")
        XCTAssertEqual(viewModel.fields.email, "woo@store.com")
    }

    func test_validating_contact_info_after_editing_all_fields_returns_updated_fields() async throws {
        // Given
        let viewModel = DomainContactInfoFormViewModel(siteID: 134,
                                                       contactInfoToEdit: Fixtures.contactInfo,
                                                       domain: "woo.com",
                                                       source: .settings,
                                                       storageManager: ServiceLocator.storageManager,
                                                       stores: stores,
                                                       analytics: ServiceLocator.analytics)
        mockRemoteValidation(result: .success(()))
        mockCountriesData(result: .success(Fixtures.countries))

        // When
        viewModel.fields.firstName = "Oow"
        viewModel.fields.lastName = "Woo"
        viewModel.fields.company = "Woo"
        viewModel.fields.address1 = "333 1st St"
        viewModel.fields.address2 = "#228"
        viewModel.fields.postcode = "94303"
        viewModel.fields.city = "Palo Alto"
        viewModel.fields.state = ""
        viewModel.fields.selectedCountry = .init(code: "CA", name: "Canada", states: [])
        viewModel.fields.phoneCountryCode = "+1"
        viewModel.fields.phone = "650-123-4567"
        viewModel.fields.email = "woo+test@store.com"
        let validatedContactInfo = try await viewModel.validateContactInfo()

        // Then
        XCTAssertEqual(validatedContactInfo.firstName, "Oow")
        XCTAssertEqual(validatedContactInfo.lastName, "Woo")
        XCTAssertEqual(validatedContactInfo.organization, "Woo")
        XCTAssertEqual(validatedContactInfo.address1, "333 1st St")
        XCTAssertEqual(validatedContactInfo.address2, "#228")
        XCTAssertEqual(validatedContactInfo.postcode, "94303")
        XCTAssertEqual(validatedContactInfo.city, "Palo Alto")
        XCTAssertEqual(validatedContactInfo.state, "")
        XCTAssertEqual(validatedContactInfo.countryCode, "CA")
        XCTAssertEqual(validatedContactInfo.phone, "+1.6501234567")
        XCTAssertEqual(validatedContactInfo.email, "woo+test@store.com")
    }
}

private extension DomainContactInfoFormViewModelTests {
    func mockRemoteValidation(result: Result<Void, Error>) {
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            if case let .validate(_, _, completion) = action {
                completion(result)
            }
        }
    }

    func mockCountriesData(result: Result<[Country], Error>) {
        stores.whenReceivingAction(ofType: DataAction.self) { action in
            if case let .synchronizeCountries(_, completion) = action {
                completion(result)
            }
        }
    }
}

private extension DomainContactInfoFormViewModelTests {
    enum Fixtures {
        static let contactInfo: DomainContactInfo = .init(firstName: "Woo",
                                                          lastName: "Testing",
                                                          organization: "WooCommerce org",
                                                          address1: "335 2nd St",
                                                          address2: "Apt 222",
                                                          postcode: "94111",
                                                          city: "San Francisco",
                                                          state: "CA",
                                                          countryCode: "US",
                                                          phone: "+886.911123456",
                                                          email: "woo@store.com")
        static let countries: [Country] = [
            .init(code: "US", name: "United States", states: [.init(code: "CA", name: "California")]),
            .init(code: "CA", name: "Canada", states: [])
        ]
    }
}
