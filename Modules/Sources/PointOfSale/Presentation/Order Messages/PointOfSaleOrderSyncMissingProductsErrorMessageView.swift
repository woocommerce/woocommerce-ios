import SwiftUI

struct PointOfSaleOrderSyncMissingProductsErrorMessageView: View {
    @Environment(\.posMetrics) private var metrics
    let missingProducts: [PointOfSaleOrderState.OrderStateError.MissingProductInfo]
    let retryHandler: () -> Void

    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.posAnalytics) private var analytics

    var body: some View {
        POSStatusScreenLayout {
            VStack(alignment: .center, spacing: metrics.spacing.none) {
                POSErrorXMark()
                Spacer().frame(height: metrics.spacing.medium)
                VStack(alignment: .center, spacing: metrics.spacing.small) {
                    Text(title)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posHeadingBold)

                    Text(subtitle)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posBodyLargeRegular())
                        .posPadding(.horizontal, \.medium)
                }
            }
        } buttons: {
            VStack(spacing: metrics.spacing.medium) {
                Button(Localization.editOrderTitle, action: {
                    let syncStrategy = posModel.isLocalCatalogEligible ? "local_catalog" : "remote"
                    analytics.track(event: .PointOfSale.checkoutOutdatedItemDetectedEditOrderTapped(
                        reason: "deleted",
                        syncStrategy: syncStrategy
                    ))
                    posModel.addMoreToCart()
                })
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                // Only show "Remove product" button if we can identify specific products
                if canIdentifySpecificProducts {
                    Button(removeProductsActionTitle, action: {
                        let syncStrategy = posModel.isLocalCatalogEligible ? "local_catalog" : "remote"

                        // Track the new specific event
                        analytics.track(event: .PointOfSale.checkoutOutdatedItemDetectedRemoveTapped(
                            reason: "deleted",
                            syncStrategy: syncStrategy
                        ))

                        // Keep existing generic event for backwards compatibility
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
        }
        .multilineTextAlignment(.center)
        .onAppear {
            let syncStrategy = posModel.isLocalCatalogEligible ? "local_catalog" : "remote"
            analytics.track(event: .PointOfSale.checkoutOutdatedItemDetectedScreenShown(
                reason: "deleted",
                syncStrategy: syncStrategy
            ))
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
           let productName = missingProducts.first?.name {
            if productName == Localization.unknownProductName {
                return Localization.subtitleGenericProduct
            } else {
                return String(format: Localization.subtitleSingular, productName)
            }
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
        let (productIDs, variationIDs) = missingProducts.extractProductAndVariationIDs()
        // Remove items from cart only (catalog was already cleaned up when error was detected)
        posModel.removeMissingProductsFromCart(productIDs: productIDs, variationIDs: variationIDs)
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
            value: "%@ is no longer available.",
            comment: "Subtitle of the error when a single product is no longer available. Placeholder is the product name."
        )

        static let subtitleGenericProduct = NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.subtitleGenericProduct",
            value: "A product in the cart is no longer available.",
            comment: "Subtitle of the error when we can't identify which specific product is no longer available."
        )

        static let subtitlePlural = NSLocalizedString(
            "pointOfSale.orderSync.missingProductsError.subtitlePlural",
            value: "Some products in your cart are no longer available.",
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
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(productID: 100, variationID: 0, name: "Blue T-Shirt")
        ],
        retryHandler: {}
    )
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#Preview("Multiple Missing Products") {
    PointOfSaleOrderSyncMissingProductsErrorMessageView(
        missingProducts: [
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(productID: 100, variationID: 0, name: "Blue T-Shirt"),
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(productID: 0, variationID: 500, name: "Red Hat")
        ],
        retryHandler: {}
    )
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
