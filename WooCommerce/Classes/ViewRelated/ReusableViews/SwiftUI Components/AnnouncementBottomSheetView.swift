import SwiftUI

struct AnnouncementBottomSheetView: View {
    @Environment(\.presentationMode) private var presentation
    @ScaledMetric private var scale: CGFloat = 1.0

    var buttonTapped: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text(Localization.title)
                .font(.headline)
                .padding(.bottom, Layout.verticalPadding)
            HStack(alignment: .center, spacing: 16.0) {
                Text(Localization.message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(uiImage: .walletImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.iconSize * scale, height: Layout.iconSize * scale)
                Spacer()
            }
            .padding(.bottom, Layout.verticalPadding)
            Button(Localization.confirmationButton) {
                if let completionHandler = buttonTapped {
                    completionHandler()
                }
                presentation.wrappedValue.dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.bottom, Layout.verticalPadding)
        }
        .padding(.leading, Layout.horizontalPadding)
        .padding(.trailing, Layout.horizontalPadding)
        .padding(.top, Layout.verticalPadding)
        .padding(.bottom, Layout.verticalPadding)
    }
}

extension AnnouncementBottomSheetView {
    enum Localization {
        static let title = NSLocalizedString("Payments from the Menu tab",
                                             comment: "Title of the bottom announcement modal when a merchant taps on Simple Payment")
        static let message = NSLocalizedString("Now you can quickly access In-Person Payments and other features with ease.",
                                               comment: "Message of the bottom announcement modal when a merchant taps on Simple Payment")
        static let confirmationButton = NSLocalizedString("Got it!",
                                                          comment: "Confirmation text of the button on the bottom announcement modal" +
                                                          "when a merchant taps on Simple Payment")
    }

    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 32
    }
}
