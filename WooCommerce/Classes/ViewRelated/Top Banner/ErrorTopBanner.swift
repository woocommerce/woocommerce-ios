import SwiftUI

/// SwiftUI view equivalent to the view created by `ErrorTopBannerFactory`.
/// TODO: if needed - convert this view to a reusable top banner.
struct ErrorTopBanner: View {
    private let errorType: ErrorTopBannerFactory.ErrorType
    private let onTroubleshootButtonPressed: () -> Void
    private let onContactSupportButtonPressed: () -> Void

    @State private var isExpanding = true

    init(error: Error,
         onTroubleshootButtonPressed: @escaping () -> Void,
         onContactSupportButtonPressed: @escaping () -> Void) {
        self.errorType = ErrorTopBannerFactory.ErrorType(error: error)
        self.onTroubleshootButtonPressed = onTroubleshootButtonPressed
        self.onContactSupportButtonPressed = onContactSupportButtonPressed
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .top) {
                Image(uiImage: .infoOutlineImage)
                    .foregroundStyle(Color(.textSubtle))
                VStack(alignment: .leading) {
                    Text(errorType.title)
                        .headlineStyle()
                    Text(errorType.info)
                        .bodyStyle()
                        .renderedIf(isExpanding)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(uiImage: isExpanding ? .chevronUpImage :
                        .chevronDownImage)
                .foregroundStyle(Color(.textSubtle))
            }
            .padding(Layout.bannerPadding)

            Divider()
            HStack {
                Button(ErrorTopBannerFactory.Localization.troubleshoot, action: onTroubleshootButtonPressed)
                    .bold()
                    .foregroundStyle(Color.withColorStudio(name: .pink, shade: .shade50))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.verticalPadding)

                Divider()

                Button(ErrorTopBannerFactory.Localization.contactSupport, action: onContactSupportButtonPressed)
                .bold()
                .foregroundStyle(Color.withColorStudio(name: .pink, shade: .shade50))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Layout.verticalPadding)
            }
            .renderedIf(isExpanding)

            Divider()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanding.toggle()
        }
    }
}

private extension ErrorTopBanner {
    enum Layout {
        static let bannerPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
    }
}

#Preview {
    ErrorTopBanner(error: NSError(domain: "Test", code: 1, userInfo: nil),
                   onTroubleshootButtonPressed: {},
                   onContactSupportButtonPressed: {})
}
