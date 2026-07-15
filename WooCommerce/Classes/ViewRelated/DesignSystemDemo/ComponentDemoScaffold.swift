#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

/// Shared layout for Design System component demos: a "Configuration" list on top and a
/// fixed-height live preview panel below.
///
/// The preview is deliberately rendered **outside** the `List`: inside a list row the
/// scroll-disambiguation touch delay swallows a custom style's press animation, so interactive
/// components wouldn't react to taps.
struct ComponentDemoScaffold<Configuration: View, Preview: View>: View {
    private let title: String
    private let previewHeight: CGFloat
    @ViewBuilder private let configuration: () -> Configuration
    @ViewBuilder private let preview: () -> Preview

    init(title: String,
         previewHeight: CGFloat = Constants.defaultPreviewHeight,
         @ViewBuilder configuration: @escaping () -> Configuration,
         @ViewBuilder preview: @escaping () -> Preview) {
        self.title = title
        self.previewHeight = previewHeight
        self.configuration = configuration
        self.preview = preview
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Configuration") {
                    configuration()
                }
                .listRowBackground(Color.storeSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.storeSectionBackground)

            preview()
                .frame(maxWidth: .infinity)
                .frame(height: previewHeight)
                .background(Color.storeSurface)
                .overlay(alignment: .top) {
                    Divider()
                }
        }
        .navigationTitle(title)
    }
}

private enum Constants {
    static let defaultPreviewHeight: CGFloat = 180
}
#endif
