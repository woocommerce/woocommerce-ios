import SwiftUI
import Yosemite

/// Shows information about an inbox note with actions and a CTA to dismiss the note.
struct InboxNoteRow: View {
    let viewModel: InboxNoteRowViewModel

    // Tracks the scale of the view due to accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Constants.spacingBetweenTopViewAndContentVStack) {
                // Relative date.
                Text(viewModel.date)
                    .font(.subheadline)
                    .foregroundColor(Color(Constants.dateTextColor))

                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
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
            }
                   .padding(Constants.defaultPadding)

            Divider()
                .frame(height: Constants.dividerHeight)
        }
    }
}

private extension InboxNoteRow {
    enum Localization {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss button in inbox note row.")
    }

    enum Constants {
        static let spacingBetweenActions: CGFloat = 16
        static let spacingBetweenTopViewAndContentVStack: CGFloat = 8
        static let verticalSpacing: CGFloat = 14
        static let defaultPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let dateTextColor: UIColor = .withColorStudio(.gray, shade: .shade30)
    }
}

struct InboxNoteRow_Previews: PreviewProvider {
    static var previews: some View {
        // Monday, February 14, 2022 1:04:42 PM
        let today = Date(timeIntervalSince1970: 1644843882)
        let note = InboxNote(siteID: 2,
                             id: 6,
                             name: "",
                             type: "marketing",
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
        let shortNote = InboxNote(siteID: 2,
                             id: 6,
                             name: "",
                             type: "",
                             status: "",
                             actions: [.init(id: 2, name: "", label: "Learn Apple Pay", status: "", url: "https://wordpress.org"),
                                       .init(id: 6, name: "", label: "No URL", status: "", url: "")],
                             title: "Boost sales this holiday season with Apple Pay!",
                             content: "Increase your conversion rate.",
                             isRemoved: false,
                             isRead: false,
                             dateCreated: today)
        Group {
            List {
                InboxNoteRow(viewModel: .init(note: note.copy(type: "marketing", dateCreated: today), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote.copy(type: "error").copy(dateCreated: today.addingTimeInterval(-6*60)), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote.copy(type: "warning").copy(dateCreated: today.addingTimeInterval(-6*3600)), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote.copy(type: "update").copy(dateCreated: today.addingTimeInterval(-6*86400)), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote.copy(type: "info").copy(dateCreated: today.addingTimeInterval(-14*86400)), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote.copy(type: "survey").copy(dateCreated: today.addingTimeInterval(-1.5*86400)), today: today))
            }
                .preferredColorScheme(.dark)
                .environment(\.sizeCategory, .extraSmall)
                .previewLayout(.sizeThatFits)
            InboxNoteRow(viewModel: .init(note: note.copy(dateCreated: today.addingTimeInterval(-86400*2)), today: today))
                .preferredColorScheme(.light)
            InboxNoteRow(viewModel: .init(note: note.copy(dateCreated: today.addingTimeInterval(-6*60)), today: today))
                .preferredColorScheme(.light)
                .environment(\.sizeCategory, .extraExtraExtraLarge)
        }
    }
}
