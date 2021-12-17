import SwiftUI

struct SiteHealthStatusChecker: View {

    @ObservedObject private var viewModel: SiteHealthStatusCheckerViewModel

    init(siteID: Int64) {
        viewModel = SiteHealthStatusCheckerViewModel(siteID: siteID)
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.requests) { request in
                    TitleAndSubtitleRow(title: request.actionName,
                                        subtitle: request.endpointName,
                                        isError: !request.success)
                }
            }
        }

        Button {
            Task {
                await viewModel.startChecking()
            }
        } label: {
            Text(Localization.startChecking)
        }
    }
}

struct SiteHealthStatusChecker_Previews: PreviewProvider {
    static var previews: some View {
        SiteHealthStatusChecker(siteID: 123)
    }
}

private extension SiteHealthStatusChecker {
    enum Localization {
        static let startChecking = NSLocalizedString(
            "Start Checking",
            comment: "Button for starting the site health status checker")
    }
}
