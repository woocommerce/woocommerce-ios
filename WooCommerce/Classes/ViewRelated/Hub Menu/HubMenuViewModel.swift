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
    }
}
