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
    }

    private enum Localization {
        static let woocommerceAdmin = NSLocalizedString("Hub Menu",
                                     comment: "Navigation bar title of hub menu view")
        static let viewStore = NSLocalizedString("Hub Menu",
                                     comment: "Navigation bar title of hub menu view")
        static let reviews = NSLocalizedString("Hub Menu",
                                     comment: "Navigation bar title of hub menu view")
    }
}
