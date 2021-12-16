import SwiftUI

struct SiteHealthStatusChecker: View {

    @ObservedObject private var viewModel: SiteHealthStatusCheckerViewModel

    init(siteID: Int64) {
        viewModel = SiteHealthStatusCheckerViewModel(siteID: siteID)
    }

    var body: some View {
        Button {
            Task {
                await viewModel.startChecking()
            }
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
