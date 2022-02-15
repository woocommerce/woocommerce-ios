import SwiftUI
import Yosemite

/// Shows information about an inbox note with actions and a CTA to dismiss the note.
struct InboxNoteRow: View {
    let viewModel: InboxNoteRowViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading,
                   spacing: Constants.verticalSpacing) {
                // HStack with type icon and relative date.
                // TODO: 5954 - type icon and relative date

                // Title.
                Text(viewModel.title)
                    .bodyStyle()
                    .fixedSize(horizontal: false, vertical: true)

                // Content.
                AttributedText(viewModel.attributedContent)
                    .attributedTextLinkColor(Color(.accent))

                // HStack with actions and dismiss action.
                HStack(spacing: Constants.spacingBetweenActions) {
                    ForEach(viewModel.actions) { action in
                        if let url = action.url {
                            Button(action.title) {
                                // TODO: 5955 - handle action
                                print("Handling action with URL: \(url)")
                            }
                            .foregroundColor(Color(.accent))
                            .font(.body)
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text(action.title)
                        }
                    }
                    Button(Localization.dismiss) {
                        // TODO: 5955 - handle dismiss action
                        print("Handling dismiss action")
                    }
                    .foregroundColor(Color(.withColorStudio(.gray, shade: .shade30)))
                    .font(.body)
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
            }
                   .padding(Constants.defaultPadding)

            if #available(iOS 15.0, *) {
                // In order to show full-width separator, the default list separator is hidden and a `Divider` is shown inside the row.
                Divider()
                    .frame(height: Constants.dividerHeight)
            }
        }
        .listRowInsets(.zero)
    }
}

private extension InboxNoteRow {
    enum Localization {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss button in inbox note row.")
    }

    enum Constants {
        static let spacingBetweenActions: CGFloat = 16
        static let verticalSpacing: CGFloat = 14
        static let defaultPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
    }
}

struct InboxNoteRow_Previews: PreviewProvider {
    static var previews: some View {
        let note = InboxNote(siteID: 2,
                             id: 6,
                             name: "",
                             type: "",
                             status: "",
                             actions: [.init(id: 2, name: "", label: "Let your customers know about Apple Pay", status: "", url: "https://wordpress.org"),
                                       .init(id: 6, name: "", label: "No URL", status: "", url: "")],
                             title: "Boost sales this holiday season with Apple Pay!",
                             content: """
  Increase your conversion rate by letting your customers know that you accept Apple Pay.
  It’s seamless to <a href=\"https://docs.woocommerce.com/document/payments/apple-pay/\">
  enable Apple Pay with WooCommerce Payments</a> and easy to communicate it with
  this <a href=\"https://developer.apple.com/apple-pay/marketing/\">marketing guide</a>.
""",
                             isRemoved: false,
                             isRead: false,
                             dateCreated: .init())
        let viewModel = InboxNoteRowViewModel(note: note)
        Group {
            InboxNoteRow(viewModel: viewModel)
                .preferredColorScheme(.dark)
            InboxNoteRow(viewModel: viewModel)
                .preferredColorScheme(.light)
            InboxNoteRow(viewModel: viewModel)
                .preferredColorScheme(.light)
                .environment(\.sizeCategory, .extraExtraExtraLarge)
        }
    }
}
