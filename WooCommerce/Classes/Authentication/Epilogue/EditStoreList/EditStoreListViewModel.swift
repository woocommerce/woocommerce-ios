import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `EditStoreListView`
///
final class EditStoreListViewModel: ObservableObject {
    /// All available sites to be displayed on the store picker
    let availableSites: [Site]

    let currentlySelectedSite: Site?

    /// Sites selected to be displayed on the store picker
    @Published var selectedSites: Set<Site>

    var hasChanges: Bool {
        selectedSites != Set(originalSelectedSites)
    }

    private let originalSelectedSites: [Site]
    private let analytics: Analytics
    private let onCompletion: () -> Void

    init(availableSites: [Site],
         displayedSites: [Site],
         currentlySelectedSite: Site?,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping () -> Void) {
        self.availableSites = availableSites.filter { $0.siteID != currentlySelectedSite?.siteID }
        self.currentlySelectedSite = currentlySelectedSite
        self.originalSelectedSites = displayedSites
        self.selectedSites = Set(displayedSites)
        self.analytics = analytics
        self.onCompletion = onCompletion
    }

    func didSaveChanges() {
        onCompletion()
    }
}

// MARK: - Helper methods for selection
extension EditStoreListViewModel {

    /// Checks if the given site is selected.
    func isSelected(_ site: Site) -> Bool {
        selectedSites.contains(site)
    }

    /// Checks if the given site is the last selected item.
    /// This is used to disable that row, so it can't be deselected.
    func isLastSelected(_ site: Site) -> Bool {
        isSelected(site) && selectedSites.count == 1
    }

    /// Selects or deselects the given site.
    func toggleSelection(_ site: Site) {
        if selectedSites.contains(site) {
            selectedSites.remove(site)
        } else {
            selectedSites.insert(site)
        }
    }
}
