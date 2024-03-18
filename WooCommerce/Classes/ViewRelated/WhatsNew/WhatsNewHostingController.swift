import SwiftUI

/// WhatsNewHostingController wrapper to handle all the specific presentation details and trait handling
final class WhatsNewHostingController: UIHostingController<ReportList> {
    override init(rootView: ReportList) {
        super.init(rootView: rootView)
        modalPresentationStyle = .formSheet
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
