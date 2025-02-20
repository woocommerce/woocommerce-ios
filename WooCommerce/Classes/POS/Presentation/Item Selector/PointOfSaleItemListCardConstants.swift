import Foundation
import SwiftUI

enum PointOfSaleItemListCardConstants {
    static let productCardSize: CGFloat = 112
    static let maximumProductCardSize: CGFloat = PointOfSaleItemListCardConstants.productCardSize * 2
    static let cardSpacing: CGFloat = POSSpacing.none
    static let horizontalTextPadding: CGFloat = POSPadding.medium
    static let verticalTextPadding: CGFloat = POSPadding.small
    static let itemTitleFont: POSFontStyle = .posBodyLargeBold
    static let itemDetailFont: POSFontStyle = .posBodyLargeRegular()
    static let accessoryButtonMaxWidth: CGFloat = 136
    static let accessoryButtonPadding: CGFloat = POSPadding.medium
    static let backgroundColor: Color = .posSurfaceContainerLowest
    static let titleColor: Color = .posOnSurface
    static let detailColor: Color = .posOnSurfaceVariantHighest
}
