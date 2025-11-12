import SwiftUI

struct PointOfSaleOrderSyncMissingProductsErrorMessageView: View {
    let missingProducts: [PointOfSaleOrderState.OrderStateError.MissingProductInfo]
    let retryHandler: () -> Void

    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.posAnalytics) private var analytics

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center) {
                Spacer()
                VStack(alignment: .center, spacing: POSSpacing.none) {
                    Spacer()
                    POSErrorXMark()
                    Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.imageAndTextSpacing)
                    VStack(alignment: .center, spacing: PointOfSaleEmptyErrorStateViewLayout.textSpacing) {
                        Text(title)
                            .foregroundStyle(Color.posOnSurface)
                            .font(.posHeadingBold)

                        Text(subtitle)
                            .foregroundStyle(Color.posOnSurface)
                            .font(.posBodyLargeRegular())
                            .padding([.leading, .trailing])
                    }
                    Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.textAndButtonSpacing)

                    VStack(spacing: PointOfSaleEmptyErrorStateViewLayout.buttonSpacing) {
                        Button(Localization.editOrderTitle, action: {
                            posModel.addMoreToCart()
                        })
                        .buttonStyle(POSFilledButtonStyle(size: .normal))

                        Button(removeProductsActionTitle, action: {
                            analytics.track(event: .PointOfSale.itemRemovedFromCart(
                                    sourceView: .error,
                                    itemType: .product
                                ))
                            removeMissingProductsFromCart()
                            retryHandler()
                        })
                        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                    }
                    .frame(width: geometry.size.width / 2)
                    .padding([.leading, .trailing], Constants.buttonSidePadding)
                    .padding([.bottom], Constants.buttonBottomPadding)

                    Spacer()
                }
                .multilineTextAlignment(.center)
                Spacer()
            }
        }
    }

    private var title: String {
        if missingProducts.count == 1 {
            return Localization.titleSingular
        } else {
            return Localization.titlePlural
        }
    }

    private var subtitle: String {
        if missingProducts.count == 1,
           let productName = missingProducts.first?.name,
           productName != Localization.unknownProductName {
            return String(format: Localization.subtitleSingular, productName)
        } else {
            return Localization.subtitlePlural
        }
    }

    private var removeProductsActionTitle: String {
        if missingProducts.count == 1 {
            return Localization.removeActionTitleSingular
        } else {
            return Localization.removeActionTitlePlural
        }
    }

    private func removeMissingProductsFromCart() {
        // Check if we have IDs available (client-side detection) or generic error (server-side)
        let missingProductIDs = Set(missingProducts.compactMap { $0.id })

        // If we have no IDs (server-side error), remove all purchasable items
        // since we can't determine which specific product is problematic
        if missingProductIDs.isEmpty {
            posModel.removeAllItemsFromCart(types: [.purchasableItem])
            return
        }

        // Find and remove items from cart that match the missing product IDs
        let itemsToRemove = posModel.cart.purchasableItems.filter { item in
            guard case .loaded(let orderableItem) = item.state else { return false }
            return missingProductIDs.contains(orderableItem.id)
        }

        for item in itemsToRemove {
            posModel.remove(cartItem: item)
        }
    }
}

private extension PointOfSaleOrderSyncMissingProductsErrorMessageView {
    enum Constants {
        static let buttonSidePadding: CGFloat = POSPadding.xxLarge
        static let buttonBottomPadding: CGFloat = POSPadding.medium
    }
}

private extension PointOfSaleOrderSyncMissingProductsErrorMessageView {
    enum Localization {
        static let titleSingular = NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.titleSingular",
            value: "Product no longer available",
            comment: "Title of the error when a single product in the cart is no longer available"
        )

        static let titlePlural = NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.titlePlural",
            value: "Products no longer available",
            comment: "Title of the error when multiple products in the cart are no longer available"
        )

        static let subtitleSingular = NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.subtitleSingular",
            value: "%@ is no longer available and couldn't be added to the order.",
            comment: "Subtitle of the error when a single product is no longer available. Placeholder is the product name."
        )

        static let subtitlePlural = NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.subtitlePlural",
            value: "Some products in your cart are no longer available and couldn't be added to the order.",
            comment: "Subtitle of the error when multiple products are no longer available"
        )

        static let removeActionTitleSingular = NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.removeProductSingular",
            value: "Remove product",
            comment: "Button title to remove a single unavailable product and retry creating the order"
        )

        static let removeActionTitlePlural = NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.removeProductsPlural",
            value: "Remove products",
            comment: "Button title to remove multiple unavailable products and retry creating the order"
        )

        static let editOrderTitle =  NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.editOrder",
            value: "Edit order",
            comment: "Button to return to order editing when products are no longer available"
        )

        static let unknownProductName = NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.unknownProductName",
            value: "One or more products",
            comment: "Generic product name used when we can't identify which specific product is unavailable"
        )
    }
}

#if DEBUG
#Preview("Single Missing Product") {
    PointOfSaleOrderSyncMissingProductsErrorMessageView(
        missingProducts: [
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(id: UUID(), name: "Blue T-Shirt", quantity: 2)
        ],
        retryHandler: {}
    )
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#Preview("Multiple Missing Products") {
    PointOfSaleOrderSyncMissingProductsErrorMessageView(
        missingProducts: [
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(id: UUID(), name: "Blue T-Shirt", quantity: 2),
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(id: UUID(), name: "Red Hat", quantity: 1)
        ],
        retryHandler: {}
    )
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
