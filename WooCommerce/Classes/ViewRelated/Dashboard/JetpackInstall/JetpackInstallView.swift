import SwiftUI

/// Hosting controller wrapper for `JetpackInstallIntroView`
///
final class JetpackInstallHostingController: UIHostingController<JetpackInstallView> {
    init(siteID: Int64, siteURL: String) {
        super.init(rootView: JetpackInstallView(siteID: siteID, siteURL: siteURL))
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

    // URL of the site to install Jetpack to
    private let siteURL: String

    // View model for `JetpackInstallStepsView`
    private let installStepsViewModel: JetpackInstallStepsViewModel

    @State private var hasStarted = false

    init(siteID: Int64, siteURL: String) {
        self.siteURL = siteURL
        self.installStepsViewModel = JetpackInstallStepsViewModel(siteID: siteID)
    }

    var body: some View {
        if hasStarted {
            JetpackInstallStepsView(siteURL: siteURL, viewModel: installStepsViewModel, dismissAction: dismissAction)
        } else {
            JetpackInstallIntroView(siteURL: siteURL, dismissAction: dismissAction) {
                hasStarted = true
            }
        }
    }
}

struct JetpackInstallView_Previews: PreviewProvider {
    static var previews: some View {
        JetpackInstallView(siteID: 123, siteURL: "automattic.com")
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 414, height: 780))
    }
}
