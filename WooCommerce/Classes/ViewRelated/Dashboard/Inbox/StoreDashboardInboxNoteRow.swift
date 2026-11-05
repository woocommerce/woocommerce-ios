import StoreDesignSystem
import SwiftUI

struct StoreDashboardInboxNoteRow: View {
    let viewModel: InboxNoteRowViewModel

    @State private var tappedAction: InboxNoteRowActionViewModel?
    @State private var isDismissButtonLoading = false
    @State private var surveyCompleted = false

    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                Text(viewModel.date)
                    .storeTextStyle(.titleSmall)

                Text(viewModel.title)
                    .storeTextStyle(viewModel.isRead || viewModel.isActioned ? .titleMedium : .titleMedium.strong)
                    .fixedSize(horizontal: false, vertical: true)

                content
                actions
            }
            .foregroundStyle(.storeOnSurface)
            .padding(StorePadding.p5)
            .frame(maxWidth: .infinity, alignment: .leading)

            StoreDivider(variant: .inset)
        }
        .sheet(item: $tappedAction) { action in
            webView(url: action.url ?? WooConstants.URLs.blog.asURL())
        }
    }

    @ViewBuilder private var content: some View {
        if viewModel.isPlaceholder {
            Text(String(repeating: " ", count: 120))
                .storeTextStyle(.bodyMedium)
        } else {
            // AttributedText wraps UIKit and needs a UIFont; StoreDesignSystem does not provide a UIFont bridge yet.
            AttributedText(viewModel.attributedContent.addingAttributes([.font: UIFont.subheadline]))
                .attributedTextLinkColor(.storePrimary)
        }
    }

    private var actions: some View {
        HStack(spacing: StoreSpacing.s5) {
            ForEach(viewModel.actions) { action in
                if viewModel.isSurvey {
                    StoreButton(action.title, variant: .outlined, action: {
                        surveyCompleted = true
                        viewModel.markInboxNoteAsActioned(actionID: action.id)
                    })
                    .fixedSize(horizontal: true, vertical: true)
                    .renderedIf(!surveyCompleted && !viewModel.isActioned)
                } else if action.url != nil {
                    Button(action.title) {
                        tappedAction = action
                        viewModel.markInboxNoteAsActioned(actionID: action.id)
                    }
                    .storeTextStyle(.bodyMedium)
                    .foregroundStyle(.storeOnSecondaryContainer)
                    .buttonStyle(.plain)
                } else {
                    Text(action.title)
                        .storeTextStyle(.bodyMedium)
                }
            }

            Text(Localization.surveyCompleted)
                .storeTextStyle(.bodyMedium)
                .renderedIf(surveyCompleted || viewModel.isSurvey && viewModel.isActioned)

            if isDismissButtonLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            } else {
                Button(Localization.dismiss) {
                    isDismissButtonLoading = true
                    viewModel.dismissInboxNote { _ in
                        isDismissButtonLoading = false
                    }
                }
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurfaceVariant)
                .buttonStyle(.plain)
                .renderedIf(!surveyCompleted || viewModel.isSurvey && !viewModel.isActioned)
            }
            Spacer(minLength: StoreSpacing.s0)
        }
    }

    private func webView(url: URL) -> some View {
        NavigationStack {
            Group {
                if viewModel.shouldAuthenticateAdminPage {
                    AuthenticatedWebView(isPresented: .constant(tappedAction != nil), url: url)
                } else {
                    WebView(isPresented: .constant(tappedAction != nil), url: url)
                }
            }
            .navigationTitle(Localization.inboxWebViewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.doneButtonWebview) { tappedAction = nil }
                }
            }
        }
    }
}

private extension StoreDashboardInboxNoteRow {
    enum Localization {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss button in inbox note row.")
        static let inboxWebViewTitle = NSLocalizedString(
            "Inbox",
            comment: "Navigation title of the webview which is used in Inbox Notes."
        )
        static let doneButtonWebview = NSLocalizedString("Done", comment: "Done navigation button in Inbox Notes webview")
        static let surveyCompleted = NSLocalizedString(
            "Thank you for your feedback!",
            comment: "Confirmation message in Inbox Notes after responding to a survey."
        )
    }
}
