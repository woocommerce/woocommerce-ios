import SwiftUI

/// Detail View of a request
///
struct SiteHealthStatusCheckerDetail: View {

    let request: SiteHealthStatusCheckerRequest

    private var errorDescription: String {
        if let error = request.error {
            return String(describing: error)
        }
        return "-"
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                TitleAndSubtitleRow(title: Localization.actionTitle, subtitle: request.actionName)
                Divider()
                TitleAndSubtitleRow(title: Localization.endpointTitle, subtitle: request.endpointName)
                Divider()
                TitleAndSubtitleRow(title: Localization.successTitle, subtitle: request.success ? Localization.successResult : Localization.failureResult)
                Divider()
                TitleAndSubtitleRow(title: Localization.errorTitle, subtitle: errorDescription)
                Divider()
                TitleAndSubtitleRow(title: Localization.totalDurationTitle, subtitle: formatTimeIntervalInSeconds(request.time))
                Divider()
            }
        }
        .navigationTitle(request.actionName)
    }
}

private extension SiteHealthStatusCheckerDetail {
    func formatTimeIntervalInSeconds(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        return formatter.string(from: timeInterval) ?? "0"
    }
}

private extension SiteHealthStatusCheckerDetail {
    enum Localization {
        static let actionTitle = NSLocalizedString(
            "Action Name",
            comment: "Action Name row in Site Health Status Checker Detail")
        static let endpointTitle = NSLocalizedString(
            "Endpoint",
            comment: "Endpoint Name row in Site Health Status Checker Detail")
        static let successTitle = NSLocalizedString(
            "Success",
            comment: "Success Name row in Site Health Status Checker Detail")
        static let errorTitle = NSLocalizedString(
            "Error",
            comment: "Error Name row in Site Health Status Checker Detail")
        static let totalDurationTitle = NSLocalizedString(
            "Total Duration",
            comment: "Total Duration Name row in Site Health Status Checker Detail")
        static let successResult = NSLocalizedString(
            "Success",
            comment: "Success subtitle in Site Health Status Checker Detail")
        static let failureResult = NSLocalizedString(
            "An error occurred",
            comment: "Error occurred subtitle in Site Health Status Checker Detail")
    }
}

struct SiteHealthStatusCheckerDetail_Previews: PreviewProvider {
    static var previews: some View {
        let request = SiteHealthStatusCheckerRequest(actionName: "Test action", endpointName: "/test", success: true, error: nil, time: 12345)
        SiteHealthStatusCheckerDetail(request: request)
    }
}
