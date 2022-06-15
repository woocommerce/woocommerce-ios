
import SwiftUI

/// a Text containing a stats value, replaced by a placeholder when the placeholder condition is met
struct StatsValueView: View {

    let value: String
    let font: Font
    let fontWeight: Font.Weight
    let foregroundColor: Color
    let lineLimit: Int?

    private var isPlaceholder: Bool {
        false
    }

    var body: some View {

        switch isPlaceholder {
        case true:
            textView.redacted(reason: .placeholder)
        case false:
            textView
        }
    }

    private var textView: some View {
        Text(value)
            .font(font)
            .fontWeight(fontWeight)
            .foregroundColor(foregroundColor)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.5)
    }
}
