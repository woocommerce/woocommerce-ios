import SwiftUI
import Shimmer

struct GhostItemCardView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posMetrics) private var metrics
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding private var showProductImage: Bool
    private let configuration: GhostItemCardViewConfiguration
    private let accessory: AnyView?

    private var dimension: CGFloat {
        min(metrics[keyPath: configuration.cardSize] * scale,
            metrics[keyPath: configuration.cardSize] * configuration.maximumCardSizeMultiplier)
    }

    init(configuration: GhostItemCardViewConfiguration = .itemList,
         showProductImage: Binding<Bool> = .constant(true)) {
        self.configuration = configuration
        self._showProductImage = showProductImage
        self.accessory = nil
    }

    init<Accessory: View>(configuration: GhostItemCardViewConfiguration = .itemList,
                          showProductImage: Binding<Bool> = .constant(true),
                         @ViewBuilder accessory: () -> Accessory) {
        self.configuration = configuration
        self._showProductImage = showProductImage
        self.accessory = AnyView(accessory())
    }

    var body: some View {
        HStack(alignment: .center, spacing: metrics.spacing.none) {
            placeholders
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Localization.loadingItemAccessibilityLabel)

            Spacer()

            if let accessory {
                accessory
                    .padding(metrics.padding.medium)
            }
        }
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : dimension)
        .background(configuration.backgroundColor)
        .posItemCardBorderStyles()
        .geometryGroup()
    }

    private var placeholders: some View {
        HStack(alignment: .center, spacing: metrics.spacing.none) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest.opacity(POSLoadingPlaceholderStyle.imageBaseOpacity))
                .frame(width: dimension, height: dimension)
                .shimmering(gradient: POSLoadingPlaceholderStyle.shimmerGradient)
                .renderedIf(showProductImage)
            VStack(alignment: .leading, spacing: metrics.spacing.xSmall) {
                POSPlaceholderText(.redactedPlaceholder(length: dynamicTypeSize.isAccessibilitySize ? 9 : 24), font: configuration.titleFont)
                POSPlaceholderText(.redactedPlaceholder(length: dynamicTypeSize.isAccessibilitySize
                                                       ? configuration.detailPlaceholderLength.accessibility
                                                       : configuration.detailPlaceholderLength.regular),
                                   font: configuration.detailFont)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, metrics.padding.medium * (1 / scale))
            .padding(.vertical, metrics.padding.small * (1 / scale))
        }
    }
}

fileprivate typealias Constants = PointOfSaleItemListCardConstants

fileprivate enum Localization {
    static let loadingItemAccessibilityLabel = NSLocalizedString(
        "pointOfSale.itemListCard.loadingItemAccessibilityLabel",
        value: "Loading",
        comment: "Loading item accessibility label in POS")
}

struct GhostItemCardViewConfiguration {
    let titleFont: POSFontStyle
    let detailFont: POSFontStyle
    let detailPlaceholderLength: (regular: Int, accessibility: Int)
    let cardSize: KeyPath<POSMetrics, CGFloat>
    let maximumCardSizeMultiplier: CGFloat
    let backgroundColor: Color

    static let itemList = GhostItemCardViewConfiguration(
        titleFont: Constants.itemTitleFont,
        detailFont: Constants.itemDetailFont,
        detailPlaceholderLength: (regular: 5, accessibility: 4),
        cardSize: \.productCardSize,
        maximumCardSizeMultiplier: Constants.maximumCardSizeMultiplier,
        backgroundColor: Color.posSurfaceBright
    )
}

#Preview {
    VStack(spacing: POSMetrics.regular.spacing.large) {
        GhostItemCardView(configuration: .itemList) {
            CartRowRemoveButton {}
        }
        GhostItemCardView(configuration: .itemList)
    }
}
