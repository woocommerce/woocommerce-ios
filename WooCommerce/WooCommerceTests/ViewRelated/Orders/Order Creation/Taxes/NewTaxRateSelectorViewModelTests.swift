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

    func test_taxRateViewModels_when_taxRate_does_not_have_location_then_it_is_filtered() {
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

        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID, onTaxRateSelected: { _ in }, stores: stores, storageManager: storageManager)

        // When
        viewModel.onLoadTriggerOnce.send()

        // Then
        XCTAssertTrue(viewModel.taxRateViewModels.isEmpty)
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
        viewModel.onRowSelected(with: 0, storeSelectedTaxRate: false)

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

    func test_onRowSelected_with_parameter_false_then_tracks_event() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let storeSelectedTaxRate = false

        // When
        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID, onTaxRateSelected: { _ in }, analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.onRowSelected(with: 1, storeSelectedTaxRate: storeSelectedTaxRate)

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.taxRateSelectorTaxRateTapped.rawValue)

        let properties = try XCTUnwrap(analytics.receivedProperties.first)
        XCTAssertEqual(properties["auto_tax_rate_enabled"] as? Bool, storeSelectedTaxRate)
    }

    func test_onRowSelected_with_parameter_true_then_tracks_event() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let storeSelectedTaxRate = true

        // When
        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID, onTaxRateSelected: { _ in }, analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.onRowSelected(with: 1, storeSelectedTaxRate: storeSelectedTaxRate)

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.taxRateSelectorTaxRateTapped.rawValue)

        let properties = try XCTUnwrap(analytics.receivedProperties.first)
        XCTAssertEqual(properties["auto_tax_rate_enabled"] as? Bool, storeSelectedTaxRate)
    }

    func test_onRowSelected_when_storeSelectedTaxRate_is_true_then_stores_tax_rate_id() {
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

        var setSelectedTaxRateIDCalledSiteID: Int64?
        var storingTaxRateID: Int64?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            guard case let .setSelectedTaxRateID(taxRateID, siteID) = action else {
                return
            }

            storingTaxRateID = taxRateID
            setSelectedTaxRateIDCalledSiteID = siteID
        }

        // When
        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID, onTaxRateSelected: { _ in }, stores: stores, storageManager: storageManager)
        viewModel.onLoadTriggerOnce.send()
        viewModel.onRowSelected(with: 0, storeSelectedTaxRate: true)

        // Then
        XCTAssertEqual(setSelectedTaxRateIDCalledSiteID, sampleSiteID)
        XCTAssertEqual(storingTaxRateID, taxRate.id)
    }

    func test_onShowWebView_then_tracks_event() {
        // Given
        let analytics = MockAnalyticsProvider()

        // When
        let viewModel = NewTaxRateSelectorViewModel(siteID: sampleSiteID, onTaxRateSelected: { _ in }, analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.onShowWebView()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.taxRateSelectorEditInAdminTapped.rawValue)
    }
}
