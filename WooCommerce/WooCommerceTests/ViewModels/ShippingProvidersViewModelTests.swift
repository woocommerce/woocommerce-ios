import Fakes
import Foundation
import Testing
import UIKit
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct ShippingProvidersViewModelTests {
    private let siteID: Int64 = 123
    private let storageManager = MockStorageManager()

    @Test func test_filter_when_only_store_country_has_providers_then_preserves_matching_results() async {
        // Given
        await insertProviders(groupName: "United States", names: ["FixtureCarrier", "LayoutCarrier"])
        let viewModel = makeViewModel(siteAddress: usSiteAddress)
        viewModel.configureResultsController()
        #expect(!viewModel.isListEmpty)
        #expect(viewModel.numberOfRowsInSection(0) == 2)
        #expect(viewModel.titleForHeaderInSection(0) == "United States")
        #expect(viewModel.titleForCellAt(IndexPath(row: 0, section: 0)) == "FixtureCarrier")
        #expect(viewModel.titleForCellAt(IndexPath(row: 1, section: 0)) == "LayoutCarrier")

        // When
        viewModel.filter(by: "Layout")

        // Then
        #expect(!viewModel.isListEmpty)
        #expect(viewModel.numberOfRowsInSection(0) == 1)
        #expect(viewModel.titleForCellAt(IndexPath(row: 0, section: 0)) == "LayoutCarrier")

        // When
        viewModel.filter(by: "MissingCarrier")

        // Then
        #expect(viewModel.isListEmpty)

        // When
        viewModel.filter(by: "Layout")

        // Then
        #expect(!viewModel.isListEmpty)
        #expect(viewModel.numberOfRowsInSection(0) == 1)
        #expect(viewModel.titleForCellAt(IndexPath(row: 0, section: 0)) == "LayoutCarrier")

        // When
        viewModel.clearFilters()

        // Then
        #expect(!viewModel.isListEmpty)
        #expect(viewModel.numberOfRowsInSection(0) == 2)
        #expect(viewModel.titleForCellAt(IndexPath(row: 0, section: 0)) == "FixtureCarrier")
        #expect(viewModel.titleForCellAt(IndexPath(row: 1, section: 0)) == "LayoutCarrier")
    }

    @Test func test_isListEmpty_when_no_providers_exist_then_ignores_custom_carrier_row() {
        // Given
        let viewModel = makeViewModel(siteAddress: usSiteAddress)

        // When
        viewModel.configureResultsController()

        // Then
        #expect(viewModel.isListEmpty)
        #expect(viewModel.numberOfSections() == 1)
        #expect(viewModel.numberOfRowsInSection(0) == 1)
        #expect(viewModel.isCustom(indexPath: IndexPath(row: 0, section: 0)))
    }

    @Test func test_isListEmpty_when_only_other_country_has_providers_then_returns_false() async throws {
        // Given
        await insertProviders(groupName: "Canada", names: ["FixtureCarrier"])
        let viewModel = makeViewModel(siteAddress: usSiteAddress)

        // When
        viewModel.configureResultsController()

        // Then
        #expect(!viewModel.isListEmpty)
        try #require(viewModel.numberOfSections() == 2)
        #expect(viewModel.numberOfRowsInSection(1) == 1)
        #expect(viewModel.titleForHeaderInSection(1) == "Canada")
        #expect(viewModel.titleForCellAt(IndexPath(row: 0, section: 1)) == "FixtureCarrier")
    }

    @Test func test_isListEmpty_when_store_country_is_unknown_and_providers_exist_then_returns_false() async {
        // Given
        await insertProviders(groupName: "United States", names: ["FixtureCarrier"])
        let viewModel = makeViewModel(siteAddress: SiteAddress(siteSettings: []))

        // When
        viewModel.configureResultsController()

        // Then
        #expect(!viewModel.isListEmpty)
        #expect(viewModel.numberOfRowsInSection(0) == 1)
        #expect(viewModel.titleForCellAt(IndexPath(row: 0, section: 0)) == "FixtureCarrier")
    }
}

private extension ShippingProvidersViewModelTests {
    var usSiteAddress: SiteAddress {
        SiteAddress(siteSettings: [SiteSetting.fake().copy(settingID: "woocommerce_default_country", value: "US")])
    }

    func makeViewModel(siteAddress: SiteAddress) -> ShippingProvidersViewModel {
        ShippingProvidersViewModel(order: Order.fake().copy(siteID: siteID),
                                   selectedProvider: nil,
                                   selectedProviderGroupName: nil,
                                   siteAddress: siteAddress,
                                   resultsControllerFactory: { groupKeyPath, predicate, sortDescriptors in
                                       ResultsController(storageManager: storageManager,
                                                         sectionNameKeyPath: groupKeyPath,
                                                         matching: predicate,
                                                         sortedBy: sortDescriptors)
                                   })
    }

    func insertProviders(groupName: String, names: [String]) async {
        let providers = names.map { ShipmentTrackingProvider(siteID: siteID, name: $0, url: "") }
        let group = ShipmentTrackingProviderGroup(name: groupName, siteID: siteID, providers: providers)
        await storageManager.performAndSaveAsync { storage in
            let storageGroup = storage.insertNewObject(ofType: StorageShipmentTrackingProviderGroup.self)
            storageGroup.update(with: group)
            for provider in group.providers {
                let storageProvider = storage.insertNewObject(ofType: StorageShipmentTrackingProvider.self)
                storageProvider.update(with: provider)
                storageGroup.addToProviders(storageProvider)
            }
        }
    }
}
