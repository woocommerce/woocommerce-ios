import SwiftUI
import NetworkingWatchOS

/// View that instructs the user how to connect to the phone.
///
struct ConnectView: View {

    @EnvironmentObject private var tracksProvider: WatchTracksProvider

    let message: String = Localization.connectMessage

    var body: some View {
        VStack(spacing: Layout.mainSpacing) {
            Text(message)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Image(systemName: "bolt.fill")
                .renderingMode(.original)
                .resizable()
                .frame(width: Layout.boltSize.width, height: Layout.boltSize.height)
                .foregroundStyle(Layout.ambarColor)
        }
        .padding(.vertical)
        .task {
            tracksProvider.sendTracksEvent(.watchConnectingOpened)
        }
    }
}

extension ConnectView {
    private enum Layout {
        static let mainSpacing = 16.0
        static let boltSize = CGSize(width: 16, height: 26)
        static let ambarColor = Color(red: 255, green: 166, blue: 14)
    }

    private enum Localization {
        static let connectMessage = AppLocalizedString(
            "watch.connect.message",
            value: "Open Woo on your iPhone, connect your store, and hold your Watch nearby",
            comment: "Info message when connecting your watch to the phone for the first time."
        )
    }
}

#Preview {
    ConnectView()
        .environmentObject(WatchTracksProvider())
}
