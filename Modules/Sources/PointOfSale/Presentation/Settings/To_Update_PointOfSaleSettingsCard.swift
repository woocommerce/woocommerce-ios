import SwiftUI

struct To_Update_PointOfSaleSettingsCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    let item: PointOfSaleSettingsView.SidebarNavigation
    let isSelected: Bool
    let onTap: () -> Void

    private var selectionBackgroundColor: Color {
        guard isSelected else { return Color.clear }
        return colorScheme == .dark ? Color.posPrimary : Color.posSecondary
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                Text(item.title)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                Text(item.subtitle)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            }
            .padding(.vertical, POSPadding.small)
            .padding(.horizontal, POSPadding.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(item.title), \(item.subtitle)")
        .background(
            RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value, style: .continuous)
                .fill(selectionBackgroundColor)
        )
    }
}
