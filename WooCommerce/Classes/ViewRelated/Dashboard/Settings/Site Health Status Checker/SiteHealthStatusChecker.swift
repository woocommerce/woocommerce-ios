import SwiftUI

struct SiteHealthStatusChecker: View {

    @ObservedObject private var viewModel: SiteHealthStatusCheckerViewModel

    init(siteID: Int64) {
        viewModel = SiteHealthStatusCheckerViewModel(siteID: siteID)
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct SiteHealthStatusChecker_Previews: PreviewProvider {
    static var previews: some View {
        SiteHealthStatusChecker(siteID: 123)
    }
}
