import SwiftUI

struct POSSettingsCardView: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                Text(title)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                Text(subtitle)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.posSurfaceContainerLowest)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .posItemCardBorderStyles()
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                        .stroke(Color.posOnSurface, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

#if DEBUG
#Preview {
    POSSettingsCardView(
        title: "Documentation",
        subtitle: "Learn more about accepting mobile payments",
        isSelected: true,
        action: { }
    )
}
#endif
