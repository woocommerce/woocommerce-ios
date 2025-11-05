import SwiftUI

struct POSSettingsCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    init(title: String, subtitle: String, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }

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
    VStack {
        POSSettingsCard(
            title: "Documentation",
            subtitle: "Learn more about accepting mobile payments",
            isSelected: true,
            action: { }
        )
        POSSettingsCard(
            title: "Documentation",
            subtitle: "Learn more about accepting mobile payments",
            isSelected: false,
            action: { }
        )
    }
}
#endif
