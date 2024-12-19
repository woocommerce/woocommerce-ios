import Foundation
import Testing
import struct Yosemite.Site
@testable import WooCommerce

struct EditStoreListViewModelTests {
    // Given
    private let site1 = Site.fake().copy(siteID: 123)
    private let site2 = Site.fake().copy(siteID: 135)

    @Test func hasChanges_returns_correct_values() {
        // Given
        let availableSites = [site1, site2]
        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               onCompletion: {})

        // Then
        #expect(viewModel.hasChanges == false)

        // When
        viewModel.selectedSites = Set([site1])

        // Then
        #expect(viewModel.hasChanges == true)
    }

    @Test func isSelected_returns_correct_values() {
        // Given
        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               onCompletion: {})

        // Then
        #expect(viewModel.isSelected(site1) == true)
        #expect(viewModel.isSelected(site2) == true)

        // When
        viewModel.selectedSites = Set([site1])

        // Then
        #expect(viewModel.isSelected(site1) == true)
        #expect(viewModel.isSelected(site2) == false)
    }

    @Test func isLastSelected_returns_correct_values() {
        // Given
        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               onCompletion: {})

        // Then
        #expect(viewModel.isLastSelected(site1) == false)

        // When
        viewModel.selectedSites = Set([site1])

        // Then
        #expect(viewModel.isLastSelected(site1) == true)
    }

    @Test func toggleSelection_works_correctly() {
        // Given
        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               onCompletion: {})

        // When
        viewModel.toggleSelection(site1)

        // Then
        #expect(viewModel.selectedSites.contains(site1) == false)

        // When
        viewModel.toggleSelection(site1)

        // Then
        #expect(viewModel.selectedSites.contains(site1) == true)
    }

    @Test func didSaveChanges_saves_hidden_store_ids_to_user_defaults_and_triggers_completion() {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        var completionTriggered = false
        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               userDefaults: userDefaults,
                                               onCompletion: { completionTriggered = true })

        // When
        viewModel.toggleSelection(site1)
        viewModel.didSaveChanges()

        // Then
        #expect(userDefaults.hiddenStoreIDs == [site1.siteID])
        #expect(completionTriggered == true)
    }
}
