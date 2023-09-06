import XCTest
import Yosemite
@testable import WooCommerce

final class NewTaxRateSelectorViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 322

    func test_wpAdminTaxSettingsURL_passes_right_url() {
        // Given
        let wpAdminTaxSettingsURL = URL(string: "https://www.site.com/wp-admin/mock-taxes-settings")
        let wpAdminTaxSettingsURLProvider = MockWPAdminTaxSettingsURLProvider(wpAdminTaxSettingsURL: wpAdminTaxSettingsURL)

        let viewModel = NewTaxRateSelectorViewModel(siteID: 1, wpAdminTaxSettingsURLProvider: wpAdminTaxSettingsURLProvider)

        XCTAssertEqual(viewModel.wpAdminTaxSettingsURL, wpAdminTaxSettingsURL)
    }

    func test_onLoadTrigger_then_calls_to_retrieveTaxRates() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var retrieveTaxRatesIsCalled = false
        stores.whenReceivingAction(ofType: TaxAction.self) { action in
            guard case .retrieveTaxRates = action else {
                return
            }
            retrieveTaxRatesIsCalled = true
        }
        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID, stores: stores)

        // When
        viewModel.onLoadTriggerOnce.send()

        // Then
        XCTAssertTrue(retrieveTaxRatesIsCalled)
    }

    func test_onRefreshAction_then_resyncs_the_first_page() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var pageNumberCalled = -1
        stores.whenReceivingAction(ofType: TaxAction.self) { action in
            guard case let .retrieveTaxRates(_, pageNumber, _, completion) = action else {
                return
            }
            pageNumberCalled = pageNumber
            completion(.success([]))
        }
        let viewModel = NewTaxRateSelectorViewModel(siteID: 1, stores: stores)

        // When
        waitFor { promise in
            viewModel.onRefreshAction {
                promise(())
            }
        }

        // Then
        XCTAssertEqual(pageNumberCalled, 1)
    }

    func test_taxRateViewModels_match_loaded_tax_rates() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        let taxRate = TaxRate.fake().copy(siteID: sampleSiteID, name: "test tax rate")
        stores.whenReceivingAction(ofType: TaxAction.self) { action in
            guard case let .retrieveTaxRates(_, _, _, completion) = action else {
                return
            }

            let newTaxRate = storageManager.viewStorage.insertNewObject(ofType: StorageTaxRate.self)
            newTaxRate.update(with: taxRate)
            storageManager.viewStorage.saveIfNeeded()
            completion(.success([taxRate]))
        }

        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        viewModel.onLoadTriggerOnce.send()

        // Then
        XCTAssertEqual(viewModel.taxRateViewModels.first?.id, taxRate.id)
        XCTAssertEqual(viewModel.taxRateViewModels.first?.name, taxRate.name)
        XCTAssertEqual(viewModel.taxRateViewModels.first?.rate, Double(taxRate.rate)?.percentFormatted() ?? "")
        XCTAssertEqual(viewModel.taxRateViewModels.first?.id, taxRate.id)
        XCTAssertEqual(viewModel.taxRateViewModels.count, 1)
    }

    func test_onLoadNextPageAction_loads_next_page() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var retrieveTaxRatesCallCount = 0
        stores.whenReceivingAction(ofType: TaxAction.self) { action in
            guard case let .retrieveTaxRates(_, _, _, completion) = action else {
                return
            }
            retrieveTaxRatesCallCount += 1
            completion(.success([]))
        }
        let viewModel = NewTaxRateSelectorViewModel(siteID: 1, stores: stores)

        // When
        waitFor { promise in
            viewModel.onRefreshAction {
                promise(())
            }
        }

        viewModel.onLoadTriggerOnce.send()
        viewModel.onLoadNextPageAction()

        // Then
        XCTAssertEqual(retrieveTaxRatesCallCount, 2)
    }
}
