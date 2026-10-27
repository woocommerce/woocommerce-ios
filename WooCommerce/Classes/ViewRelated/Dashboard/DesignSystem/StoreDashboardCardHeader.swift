import StoreDesignSystem
import SwiftUI

struct StoreDashboardCardHeader<Actions: View>: View {
    private let title: String
    private let showsError: Bool
    private let actions: Actions

    init(_ title: String,
         showsError: Bool = false,
         @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.showsError = showsError
        self.actions = actions()
    }

    var body: some View {
        HStack(spacing: StoreSpacing.s3) {
            if showsError {
                StoreIcon.CircleInfo.regular.image(size: .medium)
                    .foregroundStyle(.storeError)
                    .accessibilityHidden(true)
            }

            Text(title)
                .storeTextStyle(.titleMedium.emphasized)
                .foregroundStyle(.storeOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions
        }
        .padding(.horizontal, StorePadding.p7)
        .padding(.top, StorePadding.p7)
    }
}
