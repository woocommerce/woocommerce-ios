import SwiftUI

struct BannerPopover: View {
    /// Whether the popover is presented.
    ///
    @Binding var isPresented: Bool

    /// Configuration for the popover.
    ///
    var config: Configuration

    /// View model for the link webview.
    ///
    /// Setting this view model displays the webview in a sheet.
    ///
    @State private var webviewViewModel: WebViewSheetViewModel?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            HStack(alignment: .center) {
                Text(config.title)
                    .foregroundStyle(Color(.textInverted))
                    .font(.headline)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(uiImage: .closeButton)
                        .resizable()
                        .frame(width: Layout.buttonSize, height: Layout.buttonSize)
                        .foregroundStyle(Color(.invertedSecondaryLabel))
                }
            }

            Text(config.message)
                .foregroundStyle(Color(.textInverted))

            Button {
                webviewViewModel = WebViewSheetViewModel(url: config.buttonURL, navigationTitle: config.buttonTitle, authenticated: false)
            } label: {
                Text(config.buttonTitle)
                    .foregroundStyle(Color(.wooCommercePurple(.shade20)))
                    .bold()
                    .padding([.top], Layout.spacing)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(.invertedTooltipBackgroundColor))
                .shadow(color: Color(.secondaryLabel), radius: Layout.shadowRadius, y: Layout.shadowYOffset)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .transition(.opacity.animation(.easeInOut))
        .renderedIf(isPresented)
        .sheet(item: $webviewViewModel) { viewModel in
            WebViewSheet(viewModel: viewModel) {
                isPresented = false // Close the banner when the webview is dismissed
                webviewViewModel = nil
            }
        }
    }

    struct Configuration {
        /// Banner title.
        let title: String

        /// Banner message.
        let message: String

        /// Title for banner button.
        let buttonTitle: String

        /// URL for banner button.
        let buttonURL: URL
    }
}

private extension BannerPopover {
    enum Layout {
        static let spacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 8
        static let shadowYOffset: CGFloat = 2
        static let buttonSize: CGFloat = 16
    }
}

#Preview {
    BannerPopover(isPresented: .constant(true), config: .init(title: "Take a survey!",
                                                              message: "What do you think?",
                                                              buttonTitle: "Share your feedback",
                                                              buttonURL: WooConstants.URLs.blog.asURL()))
}
