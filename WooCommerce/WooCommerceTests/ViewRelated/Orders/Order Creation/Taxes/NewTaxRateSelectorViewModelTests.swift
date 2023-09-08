import XCTest
import Yosemite
@testable import WooCommerce

final class NewTaxRateSelectorViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 322

    func test_wpAdminTaxSettingsURL_passes_right_url() {
        // Given
        let wpAdminTaxSettingsURL = URL(string: "https://www.site.com/wp-admin/mock-taxes-settings")
        let wpAdminTaxSettingsURLProvider = MockWPAdminTaxSettingsURLProvider(wpAdminTaxSettingsURL: wpAdminTaxSettingsURL)

        let viewModel = NewTaxRateSelectorViewModel(siteID: 1, onTaxRateSelected: { _ in }, wpAdminTaxSettingsURLProvider: wpAdminTaxSettingsURLProvider)

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
        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID, onTaxRateSelected: { _ in }, stores: stores)

        // When
        viewModel.onLoadTriggerOnce.send()

        // Then
        XCTAssertTrue(retrieveTaxRatesIsCalled)
    }

    func test_taxRateViewModels_match_loaded_tax_rates() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        let taxRate = TaxRate.fake().copy(siteID: sampleSiteID, name: "test tax rate", state: "CA", country: "US", postcodes: ["12345"], cities: ["San Diego"])
        stores.whenReceivingAction(ofType: TaxAction.self) { action in
            guard case let .retrieveTaxRates(_, _, _, completion) = action else {
                return
            }

            let newTaxRate = storageManager.viewStorage.insertNewObject(ofType: StorageTaxRate.self)
            newTaxRate.update(with: taxRate)
            storageManager.viewStorage.saveIfNeeded()
            completion(.success([taxRate]))
        }

        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID, onTaxRateSelected: { _ in }, stores: stores, storageManager: storageManager)

        // When
        viewModel.onLoadTriggerOnce.send()

        // Then
        let expectedTitle = "\(taxRate.name) • \(taxRate.country) \(taxRate.state) " +
        "\(taxRate.postcodes.joined(separator: ",")) \(taxRate.cities.joined(separator: ","))"
        XCTAssertEqual(viewModel.taxRateViewModels.first?.id, taxRate.id)
        XCTAssertEqual(viewModel.taxRateViewModels.first?.title, expectedTitle)
        XCTAssertEqual(viewModel.taxRateViewModels.first?.rate, Double(taxRate.rate)?.percentFormatted() ?? "")
        XCTAssertEqual(viewModel.taxRateViewModels.first?.id, taxRate.id)
        XCTAssertEqual(viewModel.taxRateViewModels.count, 1)
    }

    func test_onRowSelected_then_calls_onTaxRateSelected_with_right_tax_rate() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        let taxRate = TaxRate.fake().copy(siteID: sampleSiteID, name: "test tax rate", country: "US", state: "CA", postcodes: ["12345"], cities: ["San Diego"])
        stores.whenReceivingAction(ofType: TaxAction.self) { action in
            guard case let .retrieveTaxRates(_, _, _, completion) = action else {
                return
            }

            let newTaxRate = storageManager.viewStorage.insertNewObject(ofType: StorageTaxRate.self)
            newTaxRate.update(with: taxRate)
            storageManager.viewStorage.saveIfNeeded()
            completion(.success([taxRate]))
        }

        var selectedTaxRate: TaxRate?
        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID,
                                                    onTaxRateSelected: { taxRate in
            selectedTaxRate = taxRate

        },
                                                    stores: stores,
                                                    storageManager: storageManager)

        // When
        viewModel.onLoadTriggerOnce.send()
        viewModel.onRowSelected(with: 0)

        // Then
        XCTAssertEqual(selectedTaxRate, taxRate)
    }

    func test_onLoadNextPageAction_loads_next_page() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var retrieveTaxRatesCallCount = 0
        let pageSize = 25
        let firstPageTaxRates = [TaxRate](repeating: .fake().copy(siteID: sampleSiteID), count: pageSize)

        stores.whenReceivingAction(ofType: TaxAction.self) { action in
            guard case let .retrieveTaxRates(_, _, _, completion) = action else {
                return
            }
            retrieveTaxRatesCallCount += 1

            completion(.success(firstPageTaxRates))
        }
        let viewModel = NewTaxRateSelectorViewModel(siteID: 1, onTaxRateSelected: { _ in }, stores: stores)

        // When
        viewModel.onLoadTriggerOnce.send()
        viewModel.onLoadNextPageAction()
        // Then
        XCTAssertEqual(retrieveTaxRatesCallCount, 2)
    }
}
