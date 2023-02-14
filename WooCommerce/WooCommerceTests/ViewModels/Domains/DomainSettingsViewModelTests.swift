import XCTest
import Yosemite
@testable import WooCommerce

final class DomainSettingsViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var viewModel: DomainSettingsViewModel!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        viewModel = DomainSettingsViewModel(siteID: 134, stores: stores)
    }

    override func tearDown() {
        viewModel = nil
        stores = nil
        super.tearDown()
    }

    // MARK: - `freeStagingDomain`

    func test_onAppear_sets_freeStagingDomain_from_first_domain_matching_isWPCOMStagingDomain() async throws {
        // Given
        mockLoadDomains(result: .success([
            .init(name: "woo.dm", isPrimary: false, isWPCOMStagingDomain: false, type: .mapping),
            .init(name: "woo.wpcomstaging.com", isPrimary: true, isWPCOMStagingDomain: true, type: .mapping),
            .init(name: "another.woo.wpcomstaging.com", isPrimary: true, isWPCOMStagingDomain: false, type: .wpcom)
        ]))
        mockLoadSiteCurrentPlan(result: .success(.init(hasDomainCredit: false)))

        // When
        await viewModel.onAppear()

        // Then
        XCTAssertEqual(viewModel.freeStagingDomain, .init(isPrimary: true, name: "woo.wpcomstaging.com"))
    }

    func test_onAppear_sets_freeStagingDomain_from_first_domain_matching_type() async throws {
        // Given
        mockLoadDomains(result: .success([
            .init(name: "woo.dm", isPrimary: false, isWPCOMStagingDomain: false, type: .mapping),
            .init(name: "woo.wordpress.com", isPrimary: true, isWPCOMStagingDomain: false, type: .wpcom),
            .init(name: "woo.wpcomstaging.com", isPrimary: true, isWPCOMStagingDomain: true, type: .mapping)
        ]))
        mockLoadSiteCurrentPlan(result: .success(.init(hasDomainCredit: false)))

        // When
        await viewModel.onAppear()

        // Then
        XCTAssertEqual(viewModel.freeStagingDomain, .init(isPrimary: true, name: "woo.wordpress.com"))
    }

    func test_onAppear_sets_freeStagingDomain_to_nil_when_no_domain_matches_isWPCOMStagingDomain_and_type() async throws {
        // Given
        mockLoadDomains(result: .success([
            .init(name: "woo.com", isPrimary: true, isWPCOMStagingDomain: false, type: .mapping)
        ]))
        mockLoadSiteCurrentPlan(result: .success(.init(hasDomainCredit: false)))

        // When
        await viewModel.onAppear()

        // Then
        XCTAssertNil(viewModel.freeStagingDomain)
    }

    // MARK: - `domains`

    func test_onAppear_sets_domains_to_non_wpcom_domains() async throws {
        // Given
        mockLoadDomains(result: .success([
            .init(name: "woo.wpcomstaging.com", isPrimary: true, isWPCOMStagingDomain: true, type: .wpcom),
            .init(name: "woo.com", isPrimary: true, isWPCOMStagingDomain: true, type: .mapping),
            .init(name: "woo.wordpress.com", isPrimary: true, isWPCOMStagingDomain: false, type: .wpcom),
        ]))
        mockLoadSiteCurrentPlan(result: .success(.init(hasDomainCredit: false)))
        XCTAssertEqual(viewModel.domains, [])

        // When
        await viewModel.onAppear()

        // Then
        XCTAssertEqual(viewModel.domains, [.init(isPrimary: true, name: "woo.com", autoRenewalDate: nil)])
    }
}

private extension DomainSettingsViewModelTests {
    func mockLoadDomains(result: Result<[SiteDomain], Error>) {
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            guard case let .loadDomains(_, completion) = action else {
                return XCTFail()
            }
            completion(result)
        }
    }

    func mockLoadSiteCurrentPlan(result: Result<WPComSitePlan, Error>) {
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            guard case let .loadSiteCurrentPlan(_, completion) = action else {
                return XCTFail()
            }
            completion(result)
        }
    }
}
