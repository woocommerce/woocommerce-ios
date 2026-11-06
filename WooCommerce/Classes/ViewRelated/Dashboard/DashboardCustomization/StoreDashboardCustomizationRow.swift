import StoreDesignSystem
import SwiftUI

struct StoreDashboardCustomizationRow: View {
    let title: String
    @Binding var isSelected: Bool
    let canToggle: Bool

    var body: some View {
        HStack(spacing: StoreSpacing.s3) {
            StoreCheckbox(isOn: $isSelected)
                .disabled(!canToggle)
                .accessibilityLabel(title)
                .accessibilityIdentifier(AccessibilityIdentifier.selection(title: title, isSelected: isSelected))

            Text(title)
                .storeTextStyle(.bodyLarge)
                .foregroundStyle(.storeOnSurface)
                .frame(maxWidth: .infinity, minHeight: StoreSize.minimumTapTarget, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: toggleSelection)
                .accessibilityHidden(true)
        }
        .listRowInsets(EdgeInsets(top: StoreSpacing.s1,
                                  leading: StorePadding.p5,
                                  bottom: StoreSpacing.s1,
                                  trailing: StorePadding.p3))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifier.row(title: title))
    }

    private func toggleSelection() {
        guard canToggle else { return }
        isSelected.toggle()
    }
}

private extension StoreDashboardCustomizationRow {
    enum AccessibilityIdentifier {
        static func row(title: String) -> String {
            "selectable-item-row-\(title)"
        }

        static func selection(title: String, isSelected: Bool) -> String {
            "selectable-item-\(isSelected ? "selected" : "unselected")-\(title)"
        }
    }
}

struct StoreDashboardCustomizationUnavailableRow: View {
    let title: String
    let badgeTitle: String

    var body: some View {
        HStack(spacing: StoreSpacing.s3) {
            StoreCheckbox(isOn: .constant(false))
                .disabled(true)
                .accessibilityHidden(true)

            Text(title)
                .storeTextStyle(.bodyLarge)
                .foregroundStyle(.storeOnSurfaceVariant)
                .frame(maxWidth: .infinity, minHeight: StoreSize.minimumTapTarget, alignment: .leading)

            StoreBadge(badgeTitle)
        }
        .listRowInsets(EdgeInsets(top: StoreSpacing.s1,
                                  leading: StorePadding.p5,
                                  bottom: StoreSpacing.s1,
                                  trailing: StorePadding.p5))
        .accessibilityElement(children: .combine)
    }
}
