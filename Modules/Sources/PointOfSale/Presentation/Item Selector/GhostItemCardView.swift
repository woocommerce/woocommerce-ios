import SwiftUI
import Shimmer

struct GhostItemCardView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var viewWidth: CGFloat = 0.0
    @Binding private var showProductImage: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let configuration: GhostItemCardViewConfiguration
    private let accessory: AnyView?

    private var dimension: CGFloat {
        let baseSize = horizontalSizeClass == .compact ? configuration.compactCardSize : configuration.cardSize
        let maxSize = horizontalSizeClass == .compact ? configuration.compactMaxCardSize : configuration.maximumCardSize
        return min(baseSize * scale, maxSize)
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
                .shimmering()
                .accessibilityLabel(Localization.loadingItemAccessibilityLabel)

            Spacer()

            if let accessory {
                accessory
                    .padding(Constants.accessoryButtonPadding)
            }
        }
        .measureWidth { width in
            viewWidth = width
        }
        .frame(maxWidth: .infinity, idealHeight: dimension)
        .background(configuration.backgroundColor)
        .posItemCardBorderStyles()
        .geometryGroup()
    }

    @ViewBuilder var placeholders: some View {
        HStack(alignment: .center, spacing: Constants.cardSpacing) {
            Rectangle()
                .frame(maxWidth: dimension)
                .aspectRatio(1, contentMode: .fill)
                .renderedIf(showProductImage)
            VStack(alignment: .leading) {
                Rectangle()
                    .frame(maxWidth: viewWidth * configuration.topPlaceholderWidthMultiplier,
                           maxHeight: configuration.placeholderHeight * min(scale, 1.5))
                    .cornerRadius(Layout.cornerRadius)
                Rectangle()
                    .frame(maxWidth: viewWidth * configuration.bottomPlaceholderWidthMultiplier,
                           maxHeight: configuration.placeholderHeight * min(scale, 1.5))
                    .cornerRadius(Layout.cornerRadius)
            }
            .foregroundColor(.posOnSurfaceVariantLowest)
            .padding(.horizontal, Constants.horizontalTextPadding)
        }
    }
}

fileprivate typealias Constants = PointOfSaleItemListCardConstants

fileprivate enum Layout {
    static let cornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
}

fileprivate enum Localization {
    static let loadingItemAccessibilityLabel = NSLocalizedString(
        "pointOfSale.itemListCard.loadingItemAccessibilityLabel",
        value: "Loading",
        comment: "Loading item accessibility label in POS")
}

struct GhostItemCardViewConfiguration {
    let placeholderHeight: CGFloat
    let cardSize: CGFloat
    let maximumCardSize: CGFloat
    let compactCardSize: CGFloat
    let compactMaxCardSize: CGFloat
    let topPlaceholderWidthMultiplier: CGFloat
    let bottomPlaceholderWidthMultiplier: CGFloat
    let backgroundColor: Color

    init(placeholderHeight: CGFloat,
         cardSize: CGFloat,
         maximumCardSize: CGFloat,
         compactCardSize: CGFloat? = nil,
         compactMaxCardSize: CGFloat? = nil,
         topPlaceholderWidthMultiplier: CGFloat,
         bottomPlaceholderWidthMultiplier: CGFloat,
         backgroundColor: Color) {
        self.placeholderHeight = placeholderHeight
        self.cardSize = cardSize
        self.maximumCardSize = maximumCardSize
        self.compactCardSize = compactCardSize ?? cardSize
        self.compactMaxCardSize = compactMaxCardSize ?? maximumCardSize
        self.topPlaceholderWidthMultiplier = topPlaceholderWidthMultiplier
        self.bottomPlaceholderWidthMultiplier = bottomPlaceholderWidthMultiplier
        self.backgroundColor = backgroundColor
    }

    static let itemList = GhostItemCardViewConfiguration(
        placeholderHeight: 32,
        cardSize: Constants.productCardSize,
        maximumCardSize: Constants.maximumProductCardSize,
        compactCardSize: 64,
        compactMaxCardSize: 96,
        topPlaceholderWidthMultiplier: 0.5,
        bottomPlaceholderWidthMultiplier: 0.1,
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
