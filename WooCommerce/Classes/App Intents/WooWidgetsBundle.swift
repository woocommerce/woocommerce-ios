import WidgetKit
import SwiftUI

struct WooWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        if #available(iOS 18, *) {
            GoToPOSControlWidget()
        }
    }
}
