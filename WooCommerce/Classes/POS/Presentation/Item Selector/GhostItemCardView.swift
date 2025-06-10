import SwiftUI

struct GhostItemCardView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var viewWidth: CGFloat = 0.0
    private let configuration: GhostItemCardViewConfiguration
    private let accessory: AnyView?

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(configuration: GhostItemCardViewConfiguration = .itemList) {
        self.configuration = configuration
        self.accessory = nil
    }

    init<Accessory: View>(configuration: GhostItemCardViewConfiguration = .itemList,
                         @ViewBuilder accessory: () -> Accessory) {
        self.configuration = configuration
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
            }
        }
        .measureWidth { width in
            viewWidth = width
        }
        .frame(maxWidth: .infinity, idealHeight: dimension)
        .background(Color.posSurfaceBright)
        .if(configuration.bordered) { $0.posItemCardBorderStyles() }
    }

    @ViewBuilder var placeholders: some View {
        HStack(alignment: .center, spacing: Constants.cardSpacing) {
            Rectangle()
                .aspectRatio(1, contentMode: .fit)
            VStack(alignment: .leading) {
                Rectangle()
                    .frame(width: viewWidth * 0.5, height: configuration.titleHeight * scale)
                    .cornerRadius(Layout.cornerRadius)
                Rectangle()
                    .frame(width: viewWidth * 0.1, height: configuration.priceHeight * scale)
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
    let titleHeight: CGFloat
    let priceHeight: CGFloat
    let bordered: Bool

    static let itemList = GhostItemCardViewConfiguration(
        titleHeight: 32,
        priceHeight: 32,
        bordered: true
    )

    static let cart = GhostItemCardViewConfiguration(
        titleHeight: 20,
        priceHeight: 20,
        bordered: false
    )
}

#Preview {
    VStack(spacing: 20) {
        GhostItemCardView(configuration: .itemList) {
            CartRowRemoveButton {}
        }
        GhostItemCardView(configuration: .cart) {
            CartRowRemoveButton {}
        }
        GhostItemCardView(configuration: .itemList)
    }
}
