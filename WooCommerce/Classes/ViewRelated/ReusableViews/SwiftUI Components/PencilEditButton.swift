import SwiftUI

/// Renders a button with the pencil system name image
///
struct PencilEditButton: View {
    @ScaledMetric private var size: CGFloat = Layout.editIconImageSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(uiImage: .pencilImage)
                .resizable()
                .frame(width: size,
                       height: size)
        }
    }
}

private extension PencilEditButton {
    enum Layout {
        static let editIconImageSize: CGFloat = 24
    }
}
