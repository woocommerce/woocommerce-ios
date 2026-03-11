import SwiftUI

/// A reusable divider styled with the POS outline variant color.
struct POSDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.posOutlineVariant.opacity(0.5))
    }
}
