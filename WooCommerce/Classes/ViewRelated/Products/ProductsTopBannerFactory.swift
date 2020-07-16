import UIKit
import Yosemite

struct ProductsTopBannerFactory {
    /// Creates a products tab top banner asynchronously based on the app settings.
    /// - Parameters:
    ///   - isExpanded: whether the top banner is expanded by default.
    ///   - expandedStateChangeHandler: called when the top banner expanded state changes.
    ///   - onCompletion: called when the view controller is created and ready for display.
    static func topBanner(isExpanded: Bool,
                          expandedStateChangeHandler: @escaping () -> Void,
                          onCompletion: @escaping (TopBannerView) -> Void) {
            let title = Strings.title
            let infoText = Strings.info
            let viewModel = TopBannerViewModel(title: title,
                                               infoText: infoText,
                                               icon: .workInProgressBanner,
                                               isExpanded: isExpanded,
                                               topButton: .chevron(handler: expandedStateChangeHandler))
            let topBannerView = TopBannerView(viewModel: viewModel)
            topBannerView.translatesAutoresizingMaskIntoConstraints = false
            onCompletion(topBannerView)
    }
}

private extension ProductsTopBannerFactory {
    enum Strings {
        static let title =
            NSLocalizedString("New editing options available",
                              comment: "The title of the Work In Progress top banner on the Products tab.")
        static let info =
            NSLocalizedString("We've added more editing functionalities to products! You can now update images, see previews and share your products.",
                              comment: "The info of the Work In Progress top banner on the Products tab.")
    }
}
