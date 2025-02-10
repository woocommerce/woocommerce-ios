import Foundation
import SwiftUI

enum PointOfSaleItemListCardConstants {
    static let productCardSize: CGFloat = 112
    static let maximumProductCardSize: CGFloat = PointOfSaleItemListCardConstants.productCardSize * 2
    static let cardSpacing: CGFloat = 0
    static let textSpacing: CGFloat = 6
    static let horizontalTextPadding: CGFloat = 16
    static let verticalTextPadding: CGFloat = 8
    static let itemTitleFont: POSFontStyle = .posBodyMediumEmphasized
    static let itemDetailFont: POSFontStyle = .posBodyMediumRegular
    static let accessoryButtonMaxWidth: CGFloat = 136
    static let accessoryButtonPadding: CGFloat = 16
    static let backgroundColor: Color = .posSurfaceContainerLowest
}
