import SwiftUI
import Shimmer

struct GhostItemCardView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding private var showProductImage: Bool
    private let configuration: GhostItemCardViewConfiguration
    private let accessory: AnyView?

    private var dimension: CGFloat {
        min(configuration.cardSize * scale, configuration.maximumCardSize)
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
        HStack(alignment: .center, spacing: Constants.cardSpacing) {
            placeholders
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Localization.loadingItemAccessibilityLabel)

            Spacer()

            if let accessory {
                accessory
                    .padding(Constants.accessoryButtonPadding)
            }
        }
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : dimension)
        .background(configuration.backgroundColor)
        .posItemCardBorderStyles()
        .geometryGroup()
    }

    private var placeholders: some View {
        HStack(alignment: .center, spacing: Constants.cardSpacing) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest.opacity(POSLoadingPlaceholderStyle.imageBaseOpacity))
                .frame(width: dimension, height: dimension)
                .shimmering(gradient: POSLoadingPlaceholderStyle.shimmerGradient)
                .renderedIf(showProductImage)
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                POSPlaceholderText(.redactedPlaceholder(length: dynamicTypeSize.isAccessibilitySize ? 9 : 24), font: configuration.titleFont)
                POSPlaceholderText(configuration.detailPlaceholder(dynamicTypeSize), font: configuration.detailFont)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
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
    let detailPlaceholder: (DynamicTypeSize) -> String
    let cardSize: CGFloat
    let maximumCardSize: CGFloat
    let backgroundColor: Color

    static let itemList = GhostItemCardViewConfiguration(
        titleFont: Constants.itemTitleFont,
        detailFont: Constants.itemDetailFont,
        detailPlaceholder: { .redactedPlaceholder(length: $0.isAccessibilitySize ? 4 : 5) },
        cardSize: Constants.productCardSize,
        maximumCardSize: Constants.maximumProductCardSize,
        backgroundColor: Color.posSurfaceBright
    )
}

#Preview {
    VStack(spacing: 20) {
        GhostItemCardView(configuration: .itemList) {
            CartRowRemoveButton {}
        }
        GhostItemCardView(configuration: .itemList)
    }
}
