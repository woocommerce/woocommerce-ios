import SwiftUI

struct POSSettingsCardView: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                Text(title)
                    .font(.posBodyLargeRegular())
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
        action: { }
    )
}
#endif
