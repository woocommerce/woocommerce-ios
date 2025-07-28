import Foundation
import SwiftUI

enum PointOfSaleItemListCardConstants {
    static let productCardSize: CGFloat = 112
    static let maximumProductCardSize: CGFloat = PointOfSaleItemListCardConstants.productCardSize * 2
    static let cardSpacing: CGFloat = POSSpacing.none
    static let textSpacing: CGFloat = POSSpacing.xSmall
    static let horizontalTextPadding: CGFloat = POSPadding.medium
    static let verticalTextPadding: CGFloat = POSPadding.small
    static let itemTitleFont: POSFontStyle = .posBodyLargeBold
    static let itemDetailFont: POSFontStyle = .posBodyLargeRegular()
    static let accessoryButtonPadding: CGFloat = POSPadding.medium
    static let backgroundColor: Color = .posSurfaceContainerLowest
    static let disabledBackgroundColor: Color = .posDisabledContainer
    static let titleColor: Color = .posOnSurface
    static let disabledTitleColor: Color = .posOnDisabledContainer
    static let detailColor: Color = .posOnSurfaceVariantHighest
}
