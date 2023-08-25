import SwiftUI

struct AdaptiveImage: View {
    @Environment(\.colorScheme) var colorScheme
    let light: UIImage
    let dark: UIImage?

    @ViewBuilder var body: some View {
        if colorScheme == .light {
            Image(uiImage: light)
                .resizable()
        } else {
            Image(uiImage: dark ?? light)
                .resizable()
        }
    }
}
