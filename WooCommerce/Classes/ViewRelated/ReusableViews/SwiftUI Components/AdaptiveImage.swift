import SwiftUI

struct AdaptiveImage: View {
    @Environment(\.colorScheme) var colorScheme
    let anyAppearance: UIImage
    let dark: UIImage?

    @ViewBuilder var body: some View {
        if colorScheme == .dark,
           let dark = dark {
            Image(uiImage: dark)
                .resizable()
        } else {
            Image(uiImage: anyAppearance)
                .resizable()
        }
    }
}
