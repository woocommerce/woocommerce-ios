import Foundation
import UIKit
import SwiftUI

/// View model for `HubMenu`.
///
final class HubMenuViewModel: ObservableObject {

    let siteID: Int64

    let storeTitle = ServiceLocator.stores.sessionManager.defaultSite?.name ?? Localization.myStore
    var storeURL: URL {
        guard let urlString = ServiceLocator.stores.sessionManager.defaultSite?.url, let url = URL(string: urlString) else {
            return WooConstants.URLs.blog.asURL()
        }

        return url
    }

    /// Child items
    ///
    @Published private(set) var menuElements: [Menu] = []

    init(siteID: Int64) {
        self.siteID = siteID
        menuElements = [.woocommerceAdmin, .viewStore, .reviews]
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
                return .starImage(size: 24.0).imageWithTintColor(.primary) ?? .starOutlineImage()
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
