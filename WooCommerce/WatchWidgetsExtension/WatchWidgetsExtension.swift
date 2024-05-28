import WidgetKit
import SwiftUI

/// Entry point for the Watch Widgets Extension
///
@main
struct WatchWidgetsExtension: WidgetBundle {
    var body: some Widget {
        // Add here any widget you want to be available
        AppLinkWidget()
    }
}
