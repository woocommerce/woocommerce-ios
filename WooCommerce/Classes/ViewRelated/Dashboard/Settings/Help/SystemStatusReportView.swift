import SwiftUI

/// Hosting controller wrapper for `SystemStatusReportView`
///
final class SystemStatusReportHostingController: UIHostingController<SystemStatusReportView> {
    init(siteID: Int64, siteURL: String) {
        super.init(rootView: SystemStatusReportView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Displays system status report
///
struct SystemStatusReportView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

struct SystemStatusReportView_Previews: PreviewProvider {
    static var previews: some View {
        SystemStatusReportView()
    }
}
