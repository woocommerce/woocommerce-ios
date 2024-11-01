import SwiftUI
import struct Yosemite.POSProduct
import protocol Yosemite.POSItem
import enum Yosemite.ProductType

protocol POSDisplayableItem: View, Identifiable, Equatable {
    var id: UUID { get }
    var item: POSItem { get }
}

func createPOSDisplayableItem(for item: POSItem) -> (any POSDisplayableItem)? {
    switch item {
    case is POSProduct:
        return POSProductItem(item: item)
    case is POSDiscount:
        return POSDiscountItem(item: item)
    default:
        return nil
    }
}

struct POSProductItem: POSDisplayableItem {
    var id: UUID {
        product.itemID
    }
    var product: POSProduct
    var item: POSItem { product }
    @EnvironmentObject var posModel: PointOfSaleAggregateModel

    init?(item: POSItem) {
        guard let product = item as? POSProduct else {
            return nil
        }
        self.product = product
    }

    var body: some View {
        Button(action: {
            let cartItem = CartItem(id: UUID(), item: product, quantity: 1)
            posModel.addItemToCart(cartItem)
        }, label: {
            ItemCardView(item: product)
        })
    }

    static func ==(lhs: POSProductItem, rhs: POSProductItem) -> Bool {
        return lhs.product == rhs.product
    }
}

struct POSDiscount: POSItem, Equatable {
    var itemID = UUID()

    var productID: Int64 = 0

    var name: String = "A fixed discount"

    var price: String = "-5.00"

    var formattedPrice: String = "-$5.00"

    var itemCategories: [String] = []

    var productImageSource: String? = nil

    var productType: Yosemite.ProductType = .simple
}

struct POSDiscountItem: POSDisplayableItem {
    var id: UUID { discount.itemID }
    let discount: POSDiscount
    var item: POSItem { discount }

    @ScaledMetric private var scale: CGFloat = 1.0

    init?(item: POSItem) {
        guard let discount = item as? POSDiscount else {
            return nil
        }
        self.discount = discount
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
                Rectangle()
                .overlay {
                    Image(systemName: "basket")
                }
                .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                       height: Constants.productCardSize * scale)
                .foregroundColor(Color(.secondarySystemFill))

            DynamicHStack(spacing: Constants.textSpacing) {
                Text(item.name)
                    .lineLimit(2)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemNameFont)
                Spacer()
                Text(item.formattedPrice)
                    .foregroundStyle(Color.posPrimaryText)
                    .font(Constants.itemPriceFont)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
        .background(Color.posSecondaryBackground)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.productCardCornerRadius)
                .stroke(Color.black, lineWidth: Constants.nilOutline)
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.productCardCornerRadius))
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }

    static func ==(lhs: POSDiscountItem, rhs: POSDiscountItem) -> Bool {
        return lhs.discount == rhs.discount
    }
}

private extension POSDiscountItem {
    enum Constants {
        static let productCardSize: CGFloat = 112
        static let maximumProductCardSize: CGFloat = Constants.productCardSize * 2
        static let productCardCornerRadius: CGFloat = 8
        // The use of stroke means the shape is rendered as an outline (border) rather than a filled shape,
        // since we still have to give it a value, we use 0 so it renders no border but it's shaped as one.
        static let nilOutline: CGFloat = 0
        static let cardSpacing: CGFloat = 0
        static let textSpacing: CGFloat = 8
        static let horizontalTextPadding: CGFloat = 32
        static let verticalTextPadding: CGFloat = 8
        static let itemNameFont: POSFontStyle = .posBodyEmphasized
        static let itemPriceFont: POSFontStyle = .posBodyRegular
    }
}
