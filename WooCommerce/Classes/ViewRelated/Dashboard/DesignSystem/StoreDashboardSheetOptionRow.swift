import StoreDesignSystem
import SwiftUI

struct StoreDashboardSheetOptionRow: View {
    let title: String
    let description: String
    let isSelected: Bool
    let isLoading: Bool
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: StoreSpacing.s5) {
                VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                    Text(title)
                        .storeTextStyle(.titleMedium.strong)
                        .foregroundStyle(.storeOnSurface)
                    Text(description)
                        .storeTextStyle(.bodyMedium)
                        .foregroundStyle(.storeOnSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                accessory
                    .frame(width: StoreSpacing.s7, height: StoreSpacing.s7)
            }
            .padding(.vertical, StorePadding.p3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    @ViewBuilder
    private var accessory: some View {
        if isLoading {
            ProgressView()
                .tint(.storePrimary)
        } else if isSelected {
            StoreIcon.Check.solid.image(size: .extraLarge)
                .foregroundStyle(.storePrimary)
                .accessibilityHidden(true)
        }
    }
}
