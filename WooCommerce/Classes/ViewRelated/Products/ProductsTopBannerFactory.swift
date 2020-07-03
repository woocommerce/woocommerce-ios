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
            NSLocalizedString("Limited editing available",
                              comment: "The title of the Work In Progress top banner on the Products tab.")
        static let info =
            NSLocalizedString("We've added editing functionality to simple products. Keep an eye out for more options soon!",
                              comment: "The info of the Work In Progress top banner on the Products tab.")
    }
}
