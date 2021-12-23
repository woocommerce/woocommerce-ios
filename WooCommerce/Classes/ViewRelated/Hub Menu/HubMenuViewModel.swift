import Foundation
import UIKit
import SwiftUI
import Combine

/// View model for `HubMenu`.
///
final class HubMenuViewModel: ObservableObject {

    @Published private(set) var siteID: Int64

    /// The view controller that will be used for presenting the `StorePickerViewController` via `StorePickerCoordinator`
    ///
    private(set) unowned var navigationController: UINavigationController?

    var storeTitle: String {
        ServiceLocator.stores.sessionManager.defaultSite?.name ?? Localization.myStore
    }
    var storeURL: URL {
        guard let urlString = ServiceLocator.stores.sessionManager.defaultSite?.url, let url = URL(string: urlString) else {
            return WooConstants.URLs.blog.asURL()
        }

        return url
    }

    /// Child items
    ///
    @Published private(set) var menuElements: [Menu] = []

    private var storePickerCoordinator: StorePickerCoordinator?

    private var cancellables = Set<AnyCancellable>()

    init(siteID: Int64, navigationController: UINavigationController? = nil) {
        self.siteID = siteID
        self.navigationController = navigationController
        menuElements = [.woocommerceAdmin, .viewStore, .reviews]
        observeSiteForUIUpdates()
    }

    /// Present the `StorePickerViewController` using the `StorePickerCoordinator`, passing the navigation controller from the entry point.
    ///
    func presentSwitchStore() {
        //TODO-5509: add analytics events
        if let navigationController = navigationController {
            storePickerCoordinator = StorePickerCoordinator(navigationController, config: .switchingStores)
            storePickerCoordinator?.start()
        }
    }

    private func observeSiteForUIUpdates() {
        ServiceLocator.stores.site.sink { [weak self] site in
            guard let self = self else { return }
            guard let siteID = site?.siteID else { return }
            self.siteID = siteID
        }.store(in: &cancellables)
    }
}

extension HubMenuViewModel {
    enum Menu: CaseIterable {
        case woocommerceAdmin
        case viewStore
        case reviews

        var title: String {
            switch self {
            case .woocommerceAdmin:
                return Localization.woocommerceAdmin
            case .viewStore:
                return Localization.viewStore
            case .reviews:
                return Localization.reviews
            }
        }

        var icon: UIImage {
            switch self {
            case .woocommerceAdmin:
                return .wordPressLogoImage.imageWithTintColor(.blue) ?? .wordPressLogoImage
            case .viewStore:
                return .storeImage.imageWithTintColor(.accent) ?? .storeImage
            case .reviews:
                return .starImage(size: 24.0).imageWithTintColor(.primary) ?? .starImage(size: 24.0)
            }
        }
    }

    private enum Localization {
        static let myStore = NSLocalizedString("My Store",
                                               comment: "Title of the hub menu view in case there is no title for the store")
        static let woocommerceAdmin = NSLocalizedString("WooCommerce Admin",
                                                        comment: "Title of one of the hub menu options")
        static let viewStore = NSLocalizedString("View Store",
                                                 comment: "Title of one of the hub menu options")
        static let reviews = NSLocalizedString("Reviews",
                                               comment: "Title of one of the hub menu options")
    }
}
