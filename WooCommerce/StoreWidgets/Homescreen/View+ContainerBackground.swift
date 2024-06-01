import SwiftUI
import WidgetKit

extension View {
    /// Adds backwards compatibility to the `containerBackground` API.
    /// This API is needed to add support to stand by mode widgets.
    ///
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, watchOSApplicationExtension 10.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
