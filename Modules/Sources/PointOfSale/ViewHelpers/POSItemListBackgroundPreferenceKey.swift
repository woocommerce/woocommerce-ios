import SwiftUI

/// Lets the dashboard paint the product pane's current surface behind system bars,
/// outside the clipping boundary that keeps its navigation content inside the safe area.
struct POSItemListBackgroundPreferenceKey: PreferenceKey {
    static let defaultValue: Color? = nil

    static func reduce(value: inout Color?, nextValue: () -> Color?) {
        value = nextValue() ?? value
    }
}
