import StoreDesignSystem
import SwiftUI

struct StoreOrderListEmptyView: View {
    let title: String
    let titleIsStrong: Bool
    let emphasizedTitle: String?
    let details: String?
    let image: UIImage
    let actionTitle: String
    let action: () -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        VStack(spacing: StoreSpacing.s8) {
            Group {
                if let emphasizedTitle, let range = title.range(of: emphasizedTitle) {
                    let prefix = Text(verbatim: String(title[..<range.lowerBound]))
                    let emphasis = Text(verbatim: emphasizedTitle).bold()
                    let suffix = Text(verbatim: String(title[range.upperBound...]))
                    prefix + emphasis + suffix
                } else {
                    Text(verbatim: title)
                }
            }
                .storeTextStyle(titleIsStrong ? .titleLarge.strong : .titleLarge)
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)

            if verticalSizeClass != .compact {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: StorePadding.p12 * 2)
                    .accessibilityHidden(true)
            }

            if let details {
                Text(details)
                    .storeTextStyle(.bodyLarge)
                    .foregroundStyle(.storeOnSurfaceVariant)
                    .multilineTextAlignment(.center)
            }

            StoreButton(actionTitle, isFullWidth: true, action: action)
                .frame(maxWidth: StorePadding.p12 * 4)
        }
        .padding(.horizontal, StorePadding.p7)
        .padding(.vertical, StorePadding.p8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.storeSurface)
    }
}
