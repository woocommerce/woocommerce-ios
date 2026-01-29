import SwiftUI

struct WPComConnectionSetupView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
            ConnectWPComHeaderView()                // title and description
            VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                Text(Localization.title)
                    .largeTitleStyle()
                    .bold()
                Text(Localization.subtitle)
                    .bodyStyle()
            }

            ScrollView {

            }
        }
    }
}

private extension WPComConnectionSetupView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let title: String = "Connect to WordPress.com"
        static let subtitle: String = "Please wait while we finalize connecting your store coffeebeans.com to your WordPress.com account."
    }
}

#Preview {
    WPComConnectionSetupView()
}
