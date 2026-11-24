import SwiftUI

/// Displays a card for a parent product in POS.
struct ParentProductCardView: View {
    private let name: String
    private let imageSource: String?
    private let detailText: String

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posMetrics) private var metrics
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var dimension: CGFloat {
        min(metrics.productCardSize * scale, metrics.productCardSize * Constants.maximumCardSizeMultiplier)
    }

    init(name: String, imageSource: String?, detailText: String) {
        self.name = name
        self.imageSource = imageSource
        self.detailText = detailText
    }

    var body: some View {
        HStack(spacing: metrics.spacing.none) {
            POSItemImageView(imageSource: imageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: metrics.spacing.xSmall) {
                Text(name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(detailText)
                    .foregroundStyle(Constants.detailColor)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, metrics.padding.medium * (1 / scale))
            .padding(.vertical, metrics.padding.small * (1 / scale))
            Spacer()

            Image(systemName: "chevron.forward")
                .accessibilityHidden(true)
                .font(.posButtonSymbolSmall)
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
                .padding(.horizontal, metrics.padding.medium * (1 / scale))
        }
        .frame(maxWidth: .infinity, idealHeight: dynamicTypeSize.isAccessibilitySize ? nil : dimension)
        .background(Constants.backgroundColor)
        .posItemCardBorderStyles()
    }
}

private typealias Constants = PointOfSaleItemListCardConstants

#if DEBUG
#Preview {
    ParentProductCardView(name: "Parent product",
                          imageSource: nil,
                          detailText: "Detail text")
}
#endif
