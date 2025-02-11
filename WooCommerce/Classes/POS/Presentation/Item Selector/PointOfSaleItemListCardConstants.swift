import Foundation
import SwiftUI

enum PointOfSaleItemListCardConstants {
    static let productCardSize: CGFloat = 112
    static let maximumProductCardSize: CGFloat = PointOfSaleItemListCardConstants.productCardSize * 2
    static let cardSpacing: CGFloat = 0
    static let textSpacing: CGFloat = 6
    static let horizontalTextPadding: CGFloat = 16
    static let verticalTextPadding: CGFloat = 8
    static let itemTitleFont: POSFontStyle = .posBodyLargeEmphasized
    static let itemDetailFont: POSFontStyle = .posBodyLargeRegular
    static let accessoryButtonMaxWidth: CGFloat = 136
    static let accessoryButtonPadding: CGFloat = 16
    static let backgroundColor: Color = .posSurfaceContainerLowest
    static let titleColor: Color = .posOnSurface
    static let detailColor: Color = .posOnSurfaceVariantHighest
}
