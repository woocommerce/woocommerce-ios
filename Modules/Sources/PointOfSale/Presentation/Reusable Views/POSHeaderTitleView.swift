import SwiftUI

struct POSHeaderTitleView: View {
    private let title: String
    private let foregroundColor: Color

    init(title: String, foregroundColor: Color = .posOnSurface) {
        self.title = title
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .posPadding(.vertical, \.large)
            .posPadding(.horizontal, \.medium)
            .font(.posHeadingBold)
            .foregroundColor(foregroundColor)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    POSHeaderTitleView(title: "Products")
}
