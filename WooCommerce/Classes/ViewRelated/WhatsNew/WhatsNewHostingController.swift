import SwiftUI

/// WhatsNewHostingController wrapper to handle all the specific presentation details and trait handling
final class WhatsNewHostingController: UIHostingController<ReportList> {
    override init(rootView: ReportList) {
        super.init(rootView: rootView)
        if UIDevice.isPad() {
            preferredContentSize = Layout.iPadContentSize
        }
        modalPresentationStyle = .formSheet
    }

    /// Since preferredContentSize may be custom (in case of iPad) we must override traitCollection in order to obtain the "real" trait collection
    override var traitCollection: UITraitCollection {
        self.presentingViewController?.traitCollection ?? .current
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Constants
//
private extension WhatsNewHostingController {
    enum Layout {
        static let iPadContentSize = CGSize(width: 360, height: 574)
    }
}
