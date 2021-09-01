import SwiftUI

/// Represents a large title, mostly to be used at the top of view controllers like What's New Component
struct LargeTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .bold()
            .multilineTextAlignment(.center)
            .largeTitleStyle()
    }
}

// MARK: - Preview
struct LargeTitle_Previews: PreviewProvider {
    static var previews: some View {
        LargeTitle(text: "What's New in WooCommerce")
    }
}
