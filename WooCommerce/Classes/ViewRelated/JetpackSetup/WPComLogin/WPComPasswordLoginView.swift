import SwiftUI

/// Screen for entering the password for a WPCom account during the Jetpack setup flow
/// This is presented for users authenticated with WPOrg credentials.
struct WPComPasswordLoginView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // title
                Text(viewModel.titleString)
                    .largeTitleStyle()

                Spacer()
            }
            .padding(Constants.contentPadding)
        }
    }
}

private extension WPComPasswordLoginView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
    }
}

struct WPComPasswordLoginView_Previews: PreviewProvider {
    static var previews: some View {
        WPComPasswordLoginView()
    }
}
