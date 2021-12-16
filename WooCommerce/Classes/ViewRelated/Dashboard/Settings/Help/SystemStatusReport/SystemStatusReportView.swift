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
}

/// Displays system status report
///
struct SystemStatusReportView: View {
    private let viewModel: SystemStatusReportViewModel

    init(viewModel: SystemStatusReportViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            Text(viewModel.statusReport)
                .multilineTextAlignment(.leading)
                .padding()
        }
    }
}

struct SystemStatusReportView_Previews: PreviewProvider {
    static var previews: some View {
        SystemStatusReportView(viewModel: .init(siteID: 123))
    }
}
