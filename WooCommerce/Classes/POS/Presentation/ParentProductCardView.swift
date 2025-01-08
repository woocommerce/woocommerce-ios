import SwiftUI
import struct Yosemite.POSParentProduct

/// Displays a card for a parent product in POS.
struct ParentProductCardView: View {
    private let parentProduct: POSParentProduct

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    init(parentProduct: POSParentProduct) {
        self.parentProduct = parentProduct
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: parentProduct.productImageSource,
                             imageSize: Constants.productCardSize * scale,
                             scale: scale)
            .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                   height: Constants.productCardSize * scale)
            .clipped()

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(parentProduct.name)
                    .lineLimit(2)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemNameFont)

                detailView()
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

private extension ParentProductCardView {
    @ViewBuilder
    func detailView() -> some View {
        switch parentProduct.type {
            case .variable:
                Text(Localization.variationsAvailable)
                    .foregroundStyle(Color.posSecondaryText)
                    .font(.posBodyRegular)
        }
    }
}

private extension ParentProductCardView {
    enum Localization {
        static let variationsAvailable = NSLocalizedString(
            "pos.parentProductCard.optionsAvailable",
            value: "Options available",
            comment: "Text indicating that there are options available for a parent product"
        )
    }
}

private extension ParentProductCardView {
    enum Constants {
        static let productCardSize: CGFloat = 112
        static let maximumProductCardSize: CGFloat = Constants.productCardSize * 2
        static let cardSpacing: CGFloat = 0
        static let textSpacing: CGFloat = 8
        static let horizontalTextPadding: CGFloat = 32
        static let verticalTextPadding: CGFloat = 8
        static let itemNameFont: POSFontStyle = .posBodyEmphasized
    }
}

#if DEBUG
#Preview {
    let parentProduct = POSParentProduct(
        id: UUID(),
        name: "Parent variable product",
        productImageSource: nil,
        productID: 42,
        type: .variable(.init())
    )
    ParentProductCardView(parentProduct: parentProduct)
}
#endif
