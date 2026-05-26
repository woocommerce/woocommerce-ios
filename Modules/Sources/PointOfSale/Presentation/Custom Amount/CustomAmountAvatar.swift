import SwiftUI

/// Square avatar that renders the first letter of a custom amount's name on
/// the standard POS surface-container background. Used in place of the generic
/// `tag` glyph wherever a single custom amount appears as a row, so multiple
/// custom amounts on the same screen are distinct at a glance.
///
/// Callers control the size by applying `.frame(...)` and the corner radius by
/// applying `.clipShape(...)` to match the surrounding row style.
struct CustomAmountAvatar: View {
    let name: String

    var body: some View {
        ZStack {
            Color.posSurfaceContainerLow

            Text(initial)
                .font(.posBodyXLargeBold)
                .foregroundColor(.posOnSurface)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
        .accessibilityHidden(true)
    }

    private var initial: String {
        guard let first = name.trimmingCharacters(in: .whitespacesAndNewlines).first else {
            return "?"
        }
        return String(first).uppercased()
    }
}

#if DEBUG
#Preview("96pt — cart row size", traits: .sizeThatFitsLayout) {
    CustomAmountAvatar(name: "Service fee")
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
        .padding()
}

#Preview("56pt — refund row size", traits: .sizeThatFitsLayout) {
    CustomAmountAvatar(name: "Tip")
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
        .padding()
}

#Preview("Empty name fallback", traits: .sizeThatFitsLayout) {
    CustomAmountAvatar(name: "")
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
        .padding()
}
#endif
