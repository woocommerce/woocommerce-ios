import SwiftUI
import Yosemite

/// Shows information about an inbox note with actions and a CTA to dismiss the note.
struct InboxNoteRow: View {
    let viewModel: InboxNoteRowViewModel
    var shouldHighlightUnreadNoteTitle = true
    var contentFont: UIFont = .body
    var dateFont: UIFont = .subheadline
    var verticalSpacing: CGFloat = 14
    var dividerPadding: EdgeInsets = .zero

    @State private var tappedAction: InboxNoteRowActionViewModel?
    @State private var isDismissButtonLoading: Bool = false
    @State private var surveyCompleted: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Constants.spacingBetweenTopViewAndContentVStack) {
                // Relative date.
                Text(viewModel.date)
                    .font(Font(dateFont))
                    .foregroundColor(Color(Constants.dateTextColor))

                VStack(alignment: .leading, spacing: verticalSpacing) {


                    // Title with status read or unread.
                    Text(viewModel.title)
                        .if(viewModel.isRead || !shouldHighlightUnreadNoteTitle) { $0.bodyStyle() }
                        .if(!viewModel.isRead && !shouldHighlightUnreadNoteTitle) { $0.headlineStyle() }
                        .fixedSize(horizontal: false, vertical: true)

                    // Content.
                    // Showing `AttributedText` in placeholder state results in animated height changes, thus a `Text` is shown instead.
                    if viewModel.isPlaceholder {
                        Text(String(repeating: " ", count: 120))
                            .bodyStyle()
                    } else {
                        AttributedText(viewModel.attributedContent.addingAttributes([.font: contentFont]))
                            .attributedTextLinkColor(Color(.accent))
                    }

                    // HStack with actions and dismiss action.
                    HStack(spacing: Constants.spacingBetweenActions) {
                        ForEach(viewModel.actions) { action in
                            if viewModel.isSurvey {
                                Button(action.title) {
                                    withAnimation(.easeInOut) {
                                        surveyCompleted = true
                                    }
                                    viewModel.markInboxNoteAsActioned(actionID: action.id)
                                }
                                .buttonStyle(SecondaryButtonStyle(labelFont: Font(contentFont)))
                                .frame(minWidth: Constants.minWidthSurveyButton)
                                .fixedSize(horizontal: true, vertical: true)
                                .renderedIf(!surveyCompleted &&  !viewModel.isActioned)
                            }
                            else if action.url != nil {
                                Button(action.title) {
                                    tappedAction = action
                                    viewModel.markInboxNoteAsActioned(actionID: action.id)
                                }
                                .foregroundColor(Color(.accent))
                                .font(Font(contentFont))
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                Text(action.title)
                                    .font(Font(contentFont))
                            }
                        }
                        .renderedIf(viewModel.showInboxCTA)

                        Text(Localization.surveyCompleted)
                            .secondaryBodyStyle()
                            .renderedIf(surveyCompleted || (viewModel.isSurvey && viewModel.isActioned))

                        if isDismissButtonLoading {
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        }
                        else {
                            Button(Localization.dismiss) {
                                isDismissButtonLoading = true
                                viewModel.dismissInboxNote { _ in
                                    isDismissButtonLoading = false
                                }
                            }
                            .foregroundColor(Color(.withColorStudio(.gray, shade: .shade30)))
                            .font(Font(contentFont))
                            .buttonStyle(PlainButtonStyle())
                            .renderedIf(!surveyCompleted || (viewModel.isSurvey && !viewModel.isActioned))
                        }
                        Spacer()
                    }
                }
            }
            .padding(Constants.defaultPadding)
            .sheet(item: $tappedAction) { action in
                webView(url: action.url ?? WooConstants.URLs.blog.asURL())
            }

            Divider()
                .frame(height: Constants.dividerHeight)
                .padding(dividerPadding)
        }
    }

    func webView(url: URL) -> some View {
        NavigationStack {
            Group {
                if viewModel.shouldAuthenticateAdminPage {
                    AuthenticatedWebView(isPresented: .constant(tappedAction != nil),
                                         url: url)
                } else {
                    WebView(isPresented: .constant(tappedAction != nil),
                            url: url)
                }
            }
            .navigationTitle(Localization.inboxWebViewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        tappedAction = nil
                    }, label: {
                        Text(Localization.doneButtonWebview)
                    })
                }
            }
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
        static let surveyCompleted = NSLocalizedString("Thank you for your feedback!",
                                                       comment: "Confirmation message in Inbox Notes after responding to a survey.")
    }

    enum Constants {
        static let spacingBetweenActions: CGFloat = 16
        static let spacingBetweenTopViewAndContentVStack: CGFloat = 8
        static let defaultPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let dateTextColor: UIColor = .withColorStudio(.gray, shade: .shade30)
        static let minWidthSurveyButton: CGFloat = 40
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
  It’s seamless to <a href=\"https://woocommerce.com/document/payments/apple-pay/\">
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

        let placeholderViewModel = InboxNoteRowViewModel(id: 1,
                                                         date: .init(),
                                                         title: "       ",
                                                         attributedContent: .init(),
                                                         actions: [],
                                                         siteID: 1,
                                                         isPlaceholder: true,
                                                         isRead: true,
                                                         isSurvey: false,
                                                         isActioned: false)
        Group {
            VStack {
                InboxNoteRow(viewModel: .init(note: note.copy(type: "marketing", dateCreated: today), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote.copy(type: "error").copy(dateCreated: today.addingTimeInterval(-6*60)), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote.copy(type: "warning").copy(dateCreated: today.addingTimeInterval(-6*3600)), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote.copy(type: "update").copy(dateCreated: today.addingTimeInterval(-6*86400)), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote.copy(type: "info").copy(dateCreated: today.addingTimeInterval(-14*86400)), today: today))
                InboxNoteRow(viewModel: .init(note: shortNote
                                                .copy(type: "survey")
                                                .copy(dateCreated: today .addingTimeInterval(-1.5*86400))
                                                .copy(title: "This is a Survey"), today: today))
            }
                .preferredColorScheme(.dark)
                .environment(\.sizeCategory, .extraSmall)
                .previewLayout(.fixed(width: 375, height: 1100))
            InboxNoteRow(viewModel: .init(note: note.copy(dateCreated: today.addingTimeInterval(-86400*2)), today: today))
                .preferredColorScheme(.light)
            InboxNoteRow(viewModel: .init(note: note.copy(dateCreated: today.addingTimeInterval(-6*60)), today: today))
                .preferredColorScheme(.light)
                .environment(\.sizeCategory, .extraExtraExtraLarge)
            InboxNoteRow(viewModel: placeholderViewModel)
                .redacted(reason: .placeholder)
                .shimmering()
                .preferredColorScheme(.light)
            InboxNoteRow(viewModel: placeholderViewModel)
                .redacted(reason: .placeholder)
                .shimmering()
                .preferredColorScheme(.dark)
        }
    }
}
