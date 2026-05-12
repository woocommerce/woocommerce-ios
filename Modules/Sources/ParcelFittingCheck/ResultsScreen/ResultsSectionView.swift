import SwiftUI

struct ResultsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption.bold())
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.bottom, ResultsSectionConstants.headerBottomPadding)

            content()
        }
    }
}

private enum ResultsSectionConstants {
    static let headerBottomPadding: CGFloat = 8
}
