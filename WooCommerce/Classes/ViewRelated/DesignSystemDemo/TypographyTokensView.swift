#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

/// Specimen list of the typography tokens — each text style rendered at its canonical
/// (regular) weight, so the type ramp can be eyeballed on-device with real Dynamic Type.
struct TypographyTokensView: View {
    var body: some View {
        List(StoreTextStyle.catalog) { token in
            VStack(alignment: .leading, spacing: 4) {
                Text(token.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("The quick brown fox")
                    .storeTextStyle(token.style)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Typography")
    }
}
#endif
