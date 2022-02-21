import SwiftUI
import Yosemite

/// Shows information about an inbox note with actions and a CTA to dismiss the note.
struct InboxNoteRow: View {
    let viewModel: InboxNoteRowViewModel

    // Tracks the scale of the view due to accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1
    @State private var actionURL: URL?
    @State private var showWebView: Bool = false
    @State private var dismissButtonIsLoading: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Constants.spacingBetweenTopHStackAndContentVStack) {
                // HStack with type icon and relative date.
                HStack {
                    Circle()
                        .frame(width: scale * Constants.typeIconDimension, height: scale * Constants.typeIconDimension, alignment: .center)
                        .foregroundColor(Color(Constants.typeIconCircleColor))
                        .overlay(
                            viewModel.typeIcon
                                    .resizable()
                                    .scaledToFit()
                                .padding(scale * Constants.typeIconPadding)
                        )
                    Text(viewModel.date)
                        .font(.subheadline)
                        .foregroundColor(Color(Constants.dateTextColor))
                    Spacer()
                }

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
                                    actionURL = url
                                    showWebView = true
                                    viewModel.markInboxNoteAsActioned()
                                }
                                .foregroundColor(Color(.accent))
                                .font(.body)
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                Text(action.title)
                            }
                        }
                        if dismissButtonIsLoading {
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        }
                        else {
                            Button(Localization.dismiss) {
                                dismissButtonIsLoading = true
                                viewModel.dismissInboxNote { _ in
                                    dismissButtonIsLoading = false
                                }
                            }
                        .foregroundColor(Color(.withColorStudio(.gray, shade: .shade30)))
                        .font(.body)
                        .buttonStyle(PlainButtonStyle())
                        }
                        Spacer()
                    }
                }
            }
            .padding(Constants.defaultPadding)
            .sheet(isPresented: $showWebView, content: {
                webView
            })

            Divider()
                .frame(height: Constants.dividerHeight)
        }
    }

    @ViewBuilder
    private var webView: some View {
        let isWPComStore = ServiceLocator.stores.sessionManager.defaultSite?.isWordPressStore ?? false
        let url = actionURL?.absoluteURL ?? WooConstants.URLs.blog.asURL()

        if isWPComStore {
        NavigationView {
            AuthenticatedWebView(isPresented: $showWebView,
                                 url: url,
                                 urlToTriggerExit: nil) {

            }
             .navigationTitle(Localization.inboxWebViewTitle)
             .navigationBarTitleDisplayMode(.inline)
             .toolbar {
                 ToolbarItem(placement: .confirmationAction) {
                     Button(action: {
                         showWebView = false
                     }, label: {
                         Text(Localization.doneButtonWebview)
                     })
                 }
             }
        }
        .wooNavigationBarStyle()
        }
        else {
            SafariSheetView(url: url)
        }
    }
}

private extension InboxNoteRow {
    enum Localization {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss button in inbox note row.")
        static let inboxWebViewTitle = NSLocalizedString(
            "Inbox",
            comment: "Navigation title of the webview which is used in Inbox Notes."
        )
        static let doneButtonWebview = NSLocalizedString("Done",
                                                         comment: "Done navigation button in Inbox Notes webview")
    }

    enum Constants {
        static let spacingBetweenActions: CGFloat = 16
        static let spacingBetweenTopHStackAndContentVStack: CGFloat = 8
        static let verticalSpacing: CGFloat = 14
        static let defaultPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let dateTextColor: UIColor = .withColorStudio(.gray, shade: .shade30)
        static let typeIconDimension: CGFloat = 29
        static let typeIconPadding: CGFloat = 5
        static let typeIconCircleColor: UIColor = .init(light: .withColorStudio(.gray, shade: .shade0), dark: .withColorStudio(.gray, shade: .shade70))
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
