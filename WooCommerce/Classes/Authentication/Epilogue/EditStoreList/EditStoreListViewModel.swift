import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `EditStoreListView`
///
final class EditStoreListViewModel: ObservableObject {
    /// All available sites to be displayed on the store picker
    let availableSites: [Site]

    /// Sites selected to be displayed on the store picker
    @Published var selectedSites: [Site]

    private let analytics: Analytics
    private let onCompletion: (_ selectedSites: [Site]) -> Void

    init(availableSites: [Site],
         selectedSites: [Site],
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping (_ selectedSites: [Site]) -> Void) {
        self.availableSites = availableSites
        self.selectedSites = selectedSites
        self.analytics = analytics
        self.onCompletion = onCompletion
    }

    func didSaveChanges() {
        onCompletion(selectedSites)
    }
}

