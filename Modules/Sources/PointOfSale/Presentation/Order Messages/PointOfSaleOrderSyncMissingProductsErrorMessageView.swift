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

                        // Only show "Remove product" button if we can identify specific products
                        if canIdentifySpecificProducts {
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

    /// Returns true if we can identify specific products to remove
    /// Returns false for generic errors where productID=0 and variationID=0
    private var canIdentifySpecificProducts: Bool {
        // If all missing products have both IDs as 0, we can't identify them
        return !missingProducts.allSatisfy { $0.productID == 0 && $0.variationID == 0 }
    }

    private func removeMissingProductsFromCart() {
        // Extract product and variation IDs from missing products
        var productIDs = Set<Int64>()
        var variationIDs = Set<Int64>()

        for missingProduct in missingProducts {
            // If variationID is non-zero, it's a variation
            if missingProduct.variationID != 0 {
                variationIDs.insert(missingProduct.variationID)
            }
            // If productID is non-zero (and variationID is zero), it's a simple product
            else if missingProduct.productID != 0 {
                productIDs.insert(missingProduct.productID)
            }
            // Skip items with both IDs as 0 (shouldn't happen since button is hidden for those)
        }

        // Remove items from cart only (catalog was already cleaned up when error was detected)
        posModel.removeMissingProductsFromCart(productIDs: productIDs, variationIDs: variationIDs)
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
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(productID: 100, variationID: 0, name: "Blue T-Shirt", quantity: 2)
        ],
        retryHandler: {}
    )
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#Preview("Multiple Missing Products") {
    PointOfSaleOrderSyncMissingProductsErrorMessageView(
        missingProducts: [
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(productID: 100, variationID: 0, name: "Blue T-Shirt", quantity: 2),
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(productID: 0, variationID: 500, name: "Red Hat", quantity: 1)
        ],
        retryHandler: {}
    )
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
