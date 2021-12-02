import Foundation

/// View model for `HubMenu`.
///
final class HubMenuViewModel: ObservableObject {

    /// Child items
    ///
    @Published private(set) var menuElements: [Menu] = []

    init() {
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

//        var icon: UIImage {
//            switch self {
//            case .woocommerceAdmin:
//
//            case .viewStore:
//            case .reviews:
//            }
//        }
    }

    private enum Localization {
        static let woocommerceAdmin = NSLocalizedString("WooCommerce Admin",
                                                        comment: "Title of one of the hub menu options")
        static let viewStore = NSLocalizedString("View Store",
                                                 comment: "Title of one of the hub menu options")
        static let reviews = NSLocalizedString("Reviews",
                                               comment: "Title of one of the hub menu options")
    }
}
