import Foundation
import Yosemite

/// View model for `BlazeCampaignCreationForm`
final class BlazeCampaignCreationFormViewModel: ObservableObject {
    let siteID: Int64
    private let stores: StoresManager
    private let completionHandler: () -> Void
    var onEditAd: (() -> Void)?

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.stores = stores
        self.completionHandler = onCompletion
    }

    func didTapEditAd() {
        onEditAd?()
    }
}
