import SwiftUI

/// Renders a button with the pencil system name image
///
struct PencilEditButton: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    private let size: CGFloat

    let action: () -> Void

    init(size: CGFloat = Layout.editIconImageSize, action: @escaping () -> Void) {
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            // Using the gridicon for pencilImage rather than the pencil SFSymbol resolves the issue,
            // however we have 50/50 cases where we're using one or the other across the app.
            // Waiting from design input in WOOMOB-516
            Image(uiImage: .pencilImage)
                .resizable()
                .frame(width: size * scale,
                       height: size * scale)
        }
    }
}

private extension PencilEditButton {
    enum Layout {
        static let editIconImageSize: CGFloat = 24
    }
}
