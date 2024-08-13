import SwiftUI

extension Font {
    static let posBody: Font = Font.system(size: UIFontMetrics.default.scaledValue(for: 24))
    static let posTitle: Font = Font.largeTitle.bold()
    static let posDetail: Font = Font.system(size: UIFontMetrics.default.scaledValue(for: 16))
    static let posModalBody: Font = Font.system(size: UIFontMetrics.default.scaledValue(for: 24))
    static let posModalTitle: Font = Font.system(size: UIFontMetrics.default.scaledValue(for: 36), weight: .bold)
}
