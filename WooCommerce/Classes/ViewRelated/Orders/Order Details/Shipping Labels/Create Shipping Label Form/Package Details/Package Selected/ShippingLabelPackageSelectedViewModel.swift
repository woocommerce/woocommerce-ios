import UIKit
import SwiftUI
import Yosemite

/// View model for `ShippingLabelPackageSelected`.
///
final class ShippingLabelPackageSelectedViewModel: ObservableObject {
    private let siteID: Int64

    private let stores: StoresManager

    /// The packages  response fetched from API
    ///
    private(set) var packagesResponse: ShippingLabelPackagesResponse?

    /// The syncing state of the view
    ///
    @Published var state: State = .syncing


    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores

        syncPackageDetails()
    }

    func syncPackageDetails() {
        state = .syncing

        let action = ShippingLabelAction.packagesDetails(siteID: siteID) { [weak self] result in
            switch result {
            case .success:
                self?.packagesResponse = try? result.get()
                self?.state = .results
            case .failure:
                self?.state = .error
            }
        }
        stores.dispatch(action)
    }

    enum State {
        case syncing
        case results
        case error
    }
}
