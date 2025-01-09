import SwiftUI

/// Displays a card for a parent product in POS.
struct ParentProductCardView<DetailView: View>: View {
    private let name: String
    private let imageSource: String?
    private let detailView: DetailView

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    init(name: String, imageSource: String?, @ViewBuilder detailView: () -> DetailView) {
        self.name = name
        self.imageSource = imageSource
        self.detailView = detailView()
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: imageSource,
                             imageSize: Constants.productCardSize * scale,
                             scale: scale)
            .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                   height: Constants.productCardSize * scale)
            .clipped()

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(name)
                    .lineLimit(2)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemNameFont)

                detailView
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
        .background(Color.posSecondaryBackground)
        .posItemCardBorderStyles()
    }
}

private enum Constants {
    static let productCardSize: CGFloat = 112
    static let maximumProductCardSize: CGFloat = Constants.productCardSize * 2
    static let cardSpacing: CGFloat = 0
    static let textSpacing: CGFloat = 8
    static let horizontalTextPadding: CGFloat = 32
    static let verticalTextPadding: CGFloat = 8
    static let itemNameFont: POSFontStyle = .posBodyEmphasized
}

#if DEBUG
#Preview {
    ParentProductCardView(name: "Parent product",
                          imageSource: nil) {
        Text("Detail view")
    }
}
#endif
