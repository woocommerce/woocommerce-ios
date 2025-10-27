import SwiftUI

struct POSSettingsSidebarNavigationCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let item: PointOfSaleSettingsView.SidebarNavigation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                Text(item.title)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                Text(item.subtitle)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(.secondary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.posSurfaceContainerLowest)
            .posItemCardBorderStyles()
        }
        .buttonStyle(.plain)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                    .stroke(Color.posOnSurface, lineWidth: 2)
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(item.title), \(item.subtitle)")
    }
}
