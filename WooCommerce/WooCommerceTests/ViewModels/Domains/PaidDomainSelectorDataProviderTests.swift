import XCTest
import Yosemite
@testable import WooCommerce

final class PaidDomainSelectorDataProviderTests: XCTestCase {
    private var stores: MockStoresManager!
    private var dataProvider: PaidDomainSelectorDataProvider!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        dataProvider = PaidDomainSelectorDataProvider(stores: stores, hasDomainCredit: false)
    }

    override func tearDown() {
        dataProvider = nil
        stores = nil
        super.tearDown()
    }

    func test_loadDomainSuggestions_returns_detail_without_sale_cost() async throws {
        // Given
        let domainWithoutSale = PaidDomainSuggestion(productID: 134,
                                                     supportsPrivacy: true,
                                                     name: "domain.nosale",
                                                     term: "year",
                                                     cost: "US$47.00",
                                                     isPremium: false)
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            switch action {
            case let .loadPaidDomainSuggestions(_, _, completion):
                completion(.success([domainWithoutSale]))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModels = try await dataProvider.loadDomainSuggestions(query: "domain")

        // Then
        XCTAssertEqual(viewModels.count, 1)

        let viewModel = viewModels[0]
        XCTAssertEqual(viewModel.name, "domain.nosale")
        XCTAssertEqual(viewModel.productID, 134)
        let viewModelPrice = String(format: PaidDomainSuggestionViewModel.Localization.priceFormat, "US$47.00", "year")
        let viewModelDetailText = try XCTUnwrap(viewModel.attributedDetail)
        XCTAssertEqual(String(viewModelDetailText.characters), viewModelPrice)
    }

    func test_loadDomainSuggestions_returns_detail_with_sale_cost() async throws {
        // Given
        let domainWithSale = PaidDomainSuggestion(productID: 18,
                                                  supportsPrivacy: true,
                                                  name: "domain.onsale",
                                                  term: "year",
                                                  cost: "US$25.00",
                                                  saleCost: "US$3.90",
                                                  isPremium: false)
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            switch action {
            case let .loadPaidDomainSuggestions(_, _, completion):
                completion(.success([domainWithSale]))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let viewModels = try await dataProvider.loadDomainSuggestions(query: "domain")

        // Then
        XCTAssertEqual(viewModels.count, 1)

        let viewModel = viewModels[0]
        XCTAssertEqual(viewModel.name, "domain.onsale")
        XCTAssertEqual(viewModel.productID, 18)
        let viewModelPrice = String(format: PaidDomainSuggestionViewModel.Localization.priceFormat, "US$25.00", "year")
        let viewModelDetailText = try XCTUnwrap(viewModel.attributedDetail)
        XCTAssertEqual(String(viewModelDetailText.characters), "US$3.90 \(viewModelPrice)")
    }

    func test_loadDomainSuggestions_with_domain_credit_returns_first_year_free_text_for_nonpremium_domain() async throws {
        // Given
        let domainWithSale = PaidDomainSuggestion(productID: 18,
                                                  supportsPrivacy: true,
                                                  name: "domain.credit",
                                                  term: "year",
                                                  cost: "US$25.00",
                                                  saleCost: "US$3.90",
                                                  isPremium: false)
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            switch action {
            case let .loadPaidDomainSuggestions(_, _, completion):
                completion(.success([domainWithSale]))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let dataProvider = PaidDomainSelectorDataProvider(stores: stores, hasDomainCredit: true)

        // When
        let viewModels = try await dataProvider.loadDomainSuggestions(query: "domain")

        // Then
        XCTAssertEqual(viewModels.count, 1)

        let viewModel = viewModels[0]
        XCTAssertEqual(viewModel.name, "domain.credit")
        XCTAssertEqual(viewModel.productID, 18)
        XCTAssertFalse(viewModel.isPremium)
        let viewModelPrice = String(format: PaidDomainSuggestionViewModel.Localization.priceFormat, "US$25.00", "year")
        let viewModelDetailText = try XCTUnwrap(viewModel.attributedDetail)
        XCTAssertEqual(String(viewModelDetailText.characters), "\(viewModelPrice) \(PaidDomainSuggestionViewModel.Localization.domainCreditPricing)")
    }

    func test_loadDomainSuggestions_with_domain_credit_returns_cost_detail_for_premium_domain() async throws {
        // Given
        let premiumDomain = PaidDomainSuggestion(productID: 18,
                                                 supportsPrivacy: true,
                                                 name: "premium.domain",
                                                 term: "year",
                                                 cost: "US$25.00",
                                                 saleCost: "US$3.90",
                                                 isPremium: true)
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            switch action {
            case let .loadPaidDomainSuggestions(_, _, completion):
                completion(.success([premiumDomain]))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let dataProvider = PaidDomainSelectorDataProvider(stores: stores, hasDomainCredit: true)

        // When
        let viewModels = try await dataProvider.loadDomainSuggestions(query: "domain")

        // Then
        XCTAssertEqual(viewModels.count, 1)

        let viewModel = viewModels[0]
        XCTAssertEqual(viewModel.name, "premium.domain")
        XCTAssertEqual(viewModel.productID, 18)
        XCTAssertTrue(viewModel.isPremium)
        let viewModelPrice = String(format: PaidDomainSuggestionViewModel.Localization.priceFormat, "US$25.00", "year")
        let viewModelDetailText = try XCTUnwrap(viewModel.attributedDetail)
        XCTAssertEqual(String(viewModelDetailText.characters), "US$3.90 \(viewModelPrice)")
    }
}
