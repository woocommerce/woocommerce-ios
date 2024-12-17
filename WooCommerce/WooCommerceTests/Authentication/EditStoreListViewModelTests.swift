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
                                               selectedSites: [site1, site2],
                                               onCompletion: { _ in })

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
                                               selectedSites: [site1, site2],
                                               onCompletion: { _ in })

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
                                               selectedSites: [site1, site2],
                                               onCompletion: { _ in })

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
                                               selectedSites: [site1, site2],
                                               onCompletion: { _ in })

        // When
        viewModel.toggleSelection(site1)

        // Then
        #expect(viewModel.selectedSites.contains(site1) == false)

        // When
        viewModel.toggleSelection(site1)

        // Then
        #expect(viewModel.selectedSites.contains(site1) == true)
    }
}
