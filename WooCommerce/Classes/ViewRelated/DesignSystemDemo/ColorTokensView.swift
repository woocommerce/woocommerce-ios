#if DEBUG || ALPHA
import SwiftUI

struct ColorTokensView: View {
    var body: some View {
        List(Color.storeColorCatalog) { token in
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(token.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3))
                    )
                Text(token.name)
                    .font(.system(.footnote, design: .monospaced))
            }
        }
        .navigationTitle("Colors")
    }
}
#endif
