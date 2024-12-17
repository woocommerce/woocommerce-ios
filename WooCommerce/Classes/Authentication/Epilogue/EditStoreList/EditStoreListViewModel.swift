import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `EditStoreListView`
///
final class EditStoreListViewModel: ObservableObject {
    /// All available sites to be displayed on the store picker
    let availableSites: [Site]

    /// Sites selected to be displayed on the store picker
    @Published var selectedSites: Set<Site>

    var hasChanges: Bool {
        selectedSites != Set(originalSelectedSites)
    }

    private let originalSelectedSites: [Site]
    private let analytics: Analytics
    private let onCompletion: (_ selectedSites: Set<Site>) -> Void

    init(availableSites: [Site],
         selectedSites: [Site],
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping (_ selectedSites: Set<Site>) -> Void) {
        self.availableSites = availableSites
        self.originalSelectedSites = selectedSites
        self.selectedSites = Set(selectedSites)
        self.analytics = analytics
        self.onCompletion = onCompletion
    }

    func didSaveChanges() {
        onCompletion(selectedSites)
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
