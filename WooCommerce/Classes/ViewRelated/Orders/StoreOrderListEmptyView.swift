import StoreDesignSystem
import SwiftUI

struct StoreOrderListEmptyView: View {
    let title: String
    let titleIsStrong: Bool
    let details: String?
    let image: UIImage
    let actionTitle: String
    let action: () -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        VStack(spacing: StoreSpacing.s8) {
            Text(title)
                .storeTextStyle(titleIsStrong ? .titleLarge.strong : .titleLarge.emphasized)
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
