import SwiftUI

/// Hosting controller wrapper for `SystemStatusReportView`
///
final class SystemStatusReportHostingController: UIHostingController<SystemStatusReportView> {
    init(siteID: Int64) {
        let viewModel = SystemStatusReportViewModel(siteID: siteID)
        super.init(rootView: SystemStatusReportView(viewModel: viewModel))
        // The navigation title is set here instead of the SwiftUI view's `navigationTitle`
        // to avoid the blinking of the title label when pushed from UIKit view.
        title = NSLocalizedString("System Status Report", comment: "Navigation title of system status report screen")
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDismissAction(_ dismissAction: @escaping () -> Void) {
        rootView.dismissAction = dismissAction
    }
}

/// Displays system status report
///
struct SystemStatusReportView: View {
    /// Dismiss action to be triggered when tapping Cancel button on error alert
    ///
    var dismissAction: () -> Void = {}

    @ObservedObject private var viewModel: SystemStatusReportViewModel
    @State private var showingErrorAlert = false

    init(viewModel: SystemStatusReportViewModel) {
        self.viewModel = viewModel
        viewModel.fetchReport()
    }

    var body: some View {
        Group {
            if viewModel.statusReport.isEmpty {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            } else {
                ScrollView {
                    Text(viewModel.statusReport)
                        .multilineTextAlignment(.leading)
                        .padding()
                }
            }
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(title: Text(Localization.errorTitle),
                  message: Text(Localization.errorMessage),
                  primaryButton: .default(Text(Localization.tryAgainButton), action: viewModel.fetchReport),
                  secondaryButton: .default(Text(Localization.cancelButton), action: dismissAction))
        }
        .onChange(of: viewModel.errorFetchingReport) { newValue in
            showingErrorAlert = newValue
        }
    }
}

private extension SystemStatusReportView {
    enum Localization {
        static let errorTitle = NSLocalizedString(
            "Error fetching report",
            comment: "Title for the error alert when fetching system status report fails"
        )
        static let errorMessage = NSLocalizedString(
            "The system status report for your site cannot be fetched at the moment. Please try again.",
            comment: "Message for the error alert when fetching system status report fails"
        )
        static let tryAgainButton = NSLocalizedString(
            "Try Again",
            comment: "Try Again button on the error alert when fetching system status report fails"
        )
        static let cancelButton = NSLocalizedString(
            "Cancel",
            comment: "Cancel button on the error alert when fetching system status report fails"
        )
    }
}

struct SystemStatusReportView_Previews: PreviewProvider {
    static var previews: some View {
        SystemStatusReportView(viewModel: .init(siteID: 123))
    }
}
