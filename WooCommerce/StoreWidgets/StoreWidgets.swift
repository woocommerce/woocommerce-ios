import WidgetKit
import SwiftUI

/// Entry point for the Widgets Extension
///
@main
struct StoreWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Add here any widget you want to be available
        StoreInfoWidget()
        AppLinkWidget()
    }
}
