import SwiftUI

/// WhatsNewHostingController wrapper to handle all the specific presentation details and trait handling
final class WhatsNewHostingController: UIHostingController<ReportList> {
    override init(rootView: ReportList) {
        super.init(rootView: rootView)
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
