import SwiftUI

struct AdaptiveAsyncImage<Content>: View where Content: View {
    @Environment(\.colorScheme) var colorScheme
    let lightUrl: URL
    let darkUrl: URL?
    @ViewBuilder var content: (AsyncImagePhase) -> Content

    /// Displays a remote image appropriate for the current dark/light display mode, using the `ViewBuilder` provided.
    /// `AsyncImage` is used to fetch the image.
    /// - Parameters:
    ///   - lightUrl: URL for a remote image to be used for light mode.
    ///   - darkUrl: Optional URL for a remote image to be used for dark mode. If not supplied, the light mode image will be used
    ///   - content: ViewBuilder to handle image display, identical usage as for AsyncImage
    init(lightUrl: URL, darkUrl: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.lightUrl = lightUrl
        self.darkUrl = darkUrl
        self.content = content
    }

    @ViewBuilder var body: some View {
        if colorScheme == .dark,
           let darkUrl = darkUrl {
            AsyncImage(url: darkUrl, content: content)
        } else {
            AsyncImage(url: lightUrl, content: content)
        }
    }
}
