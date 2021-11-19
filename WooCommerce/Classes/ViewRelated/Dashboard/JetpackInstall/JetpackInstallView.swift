import SwiftUI

/// Hosting controller wrapper for `JetpackInstallIntroView`
///
final class JetpackInstallHostingController: UIHostingController<JetpackInstallView> {
    init(siteURL: String) {
        super.init(rootView: JetpackInstallView(siteURL: siteURL))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDismissAction(_ dismissAction: @escaping () -> Void) {
        rootView.dismissAction = dismissAction
    }
}

/// Displays Jetpack Install flow.
///
struct JetpackInstallView: View {
    // Closure invoked when Close button is tapped
    var dismissAction: () -> Void = {}

    private let siteURL: String

    @State private var hasStarted = false

    init(siteURL: String) {
        self.siteURL = siteURL
    }

    var body: some View {
        if hasStarted {
            JetpackInstallStepsView(siteURL: siteURL, dismissAction: dismissAction)
        } else {
            JetpackInstallIntroView(siteURL: siteURL, dismissAction: dismissAction) {
                hasStarted = true
            }
        }
    }
}

struct JetpackInstallView_Previews: PreviewProvider {
    static var previews: some View {
        JetpackInstallView(siteURL: "automattic.com")
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 414, height: 780))
    }
}
