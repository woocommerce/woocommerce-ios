import StoreDesignSystem
import SwiftUI

struct StoreDashboardCardFooterAction: View {
    private let title: String
    private let isDisabled: Bool
    private let action: () -> Void

    init(_ title: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            StoreDivider()

            Button(action: action) {
                HStack(spacing: StoreSpacing.s3) {
                    Text(title)
                        .storeTextStyle(.bodyLarge.emphasized)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StoreIcon.AngleRight.regular.image(size: .medium)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(.storePrimary)
                .padding(StorePadding.p7)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
    }
}
