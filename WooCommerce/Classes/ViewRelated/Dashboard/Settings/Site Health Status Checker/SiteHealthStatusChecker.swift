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
                    TitleAndSubtitleRow(title: request.actionName ?? "",
                                        subtitle: request.endpointName ?? "",
                                        isError: !(request.success ?? true))
                }
            }
        }

        Button {
            viewModel.startChecking()
        } label: {
            Text("Start checking")
        }
    }
}

struct SiteHealthStatusChecker_Previews: PreviewProvider {
    static var previews: some View {
        SiteHealthStatusChecker(siteID: 123)
    }
}
