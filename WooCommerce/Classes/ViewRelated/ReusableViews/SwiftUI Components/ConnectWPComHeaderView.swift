import SwiftUI

/// Shared header for WPCom login screens in the notification setup flow
struct ConnectWPComHeaderView: View {
    @ScaledMetric private var scale = 1

    var body: some View {
        Image(uiImage: .connectWPComImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: Constants.wpcomIconHeight * scale)
    }

    enum Constants {
        static let wpcomIconHeight: CGFloat = 48
    }
}
