import SwiftUI

struct POSSettingsCardView: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                Text(title)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                Text(subtitle)
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
