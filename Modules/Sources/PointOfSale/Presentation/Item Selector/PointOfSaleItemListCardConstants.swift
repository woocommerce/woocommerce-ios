import Foundation
import SwiftUI

enum PointOfSaleItemListCardConstants {
    static let maximumCardSizeMultiplier: CGFloat = 2
    static let itemTitleFont: POSFontStyle = .posBodyLargeBold
    static let itemDetailFont: POSFontStyle = .posBodyLargeRegular()
    static let backgroundColor: Color = .posSurfaceContainerLowest
    static let disabledBackgroundColor: Color = .posDisabledContainer
    static let titleColor: Color = .posOnSurface
    static let disabledTitleColor: Color = .posOnDisabledContainer
    static let detailColor: Color = .posOnSurfaceVariantHighest

    static func stacksContent(metrics: POSMetrics, dynamicTypeSize: DynamicTypeSize) -> Bool {
        metrics == .compact && dynamicTypeSize.isAccessibilitySize
    }

    static func imageSize(metrics: POSMetrics, scale: CGFloat, dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        if stacksContent(metrics: metrics, dynamicTypeSize: dynamicTypeSize) {
            return metrics.productCardSize
        }
        return min(metrics.productCardSize * scale, metrics.productCardSize * maximumCardSizeMultiplier)
    }
}

struct POSItemCardLayout<CardImage: View, Details: View, Accessory: View>: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posMetrics) private var metrics
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let image: CardImage
    private let details: Details
    private let accessory: Accessory

    init(@ViewBuilder image: () -> CardImage,
         @ViewBuilder details: () -> Details,
         @ViewBuilder accessory: () -> Accessory = { EmptyView() }) {
        self.image = image()
        self.details = details()
        self.accessory = accessory()
    }

    var body: some View {
        if PointOfSaleItemListCardConstants.stacksContent(metrics: metrics, dynamicTypeSize: dynamicTypeSize) {
            VStack(alignment: .leading, spacing: metrics.spacing.none) {
                HStack(spacing: metrics.spacing.none) {
                    image
                    Spacer(minLength: metrics.spacing.none)
                    accessory
                }
                details
                    .padding(.horizontal, metrics.padding.medium)
                    .padding(.vertical, metrics.padding.small)
            }
        } else {
            HStack(spacing: metrics.spacing.none) {
                image
                details
                    .padding(.horizontal, metrics.padding.medium * (1 / scale))
                    .padding(.vertical, metrics.padding.small * (1 / scale))
                Spacer()
                accessory
            }
        }
    }
}
