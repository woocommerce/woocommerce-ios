import SwiftUI

struct BottomAnnouncementView: View {
    @Environment(\.presentationMode) private var presentation

    var buttonTapped: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text(Localization.title)
                .font(.headline)
                .padding(.bottom, Layout.titleFontSize)
            Text(Localization.message)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, Layout.messageFontSize)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Button(Localization.confirmationButton) {
                if let completionHandler = buttonTapped {
                    completionHandler()
                }
                presentation.wrappedValue.dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.bottom, Layout.bottomPadding)
        }
        .padding(.leading, Layout.horizontalPadding)
        .padding(.trailing, Layout.horizontalPadding)
        .padding(.top, Layout.verticalPadding)
        .padding(.bottom, Layout.verticalPadding)
        .background(RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(Color(.withColorStudio(.gray, shade: .shade0))))
    }
}

extension BottomAnnouncementView {
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
        static let titleFontSize: CGFloat = 16
        static let messageFontSize: CGFloat = 16
        static let horizontalPadding: CGFloat = 6
        static let verticalPadding: CGFloat = 4
        static let bottomPadding: CGFloat = 6
        static let cornerRadius: CGFloat = 12
    }
}
