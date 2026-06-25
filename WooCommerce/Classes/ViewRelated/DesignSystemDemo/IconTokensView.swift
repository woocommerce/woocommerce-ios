#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

/// Specimen list of the icon tokens — one row per icon showing every style variant it
/// ships (light / regular / solid), tinted with the icon color token, so the full set can
/// be verified on-device.
struct IconTokensView: View {
    var body: some View {
        List(StoreIcon.catalog) { token in
            VStack(alignment: .leading, spacing: 8) {
                Text(token.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 24) {
                    ForEach(token.variants, id: \.style) { variant in
                        VStack(spacing: 4) {
                            variant.image(size: StoreIconSize.extraLarge)
                                .foregroundStyle(Color.storeIconPrimary)
                            Text(variant.style)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Icons")
    }
}
#endif
