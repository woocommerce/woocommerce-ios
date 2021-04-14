import UIKit
import SwiftUI
import Yosemite

/// View model for `ShippingLabelAddNewPackage`.
///
final class ShippingLabelAddNewPackageViewModel: ObservableObject {
    private let siteID: Int64

    /// The selected index in the SegmentedView
    ///
    @Published var selectedIndex: Int

    private let stores: StoresManager

    /// The packages  response fetched from API
    ///
    private(set) var packagesResponse: ShippingLabelPackagesResponse?

    /// The syncing state of the view
    ///
    @Published var state: State = .syncing


    init(siteID: Int64,
         selectedIndex: Int = SelectedIndex.servicePackage.rawValue,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.selectedIndex = selectedIndex
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

    enum SelectedIndex: Int {
        case customPackage = 0
        case servicePackage = 1
    }
}
