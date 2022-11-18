import Foundation
import SwiftUI

/// Main Analytics Hub View
///
struct AnalyticsHubView: View {

    var body: some View {
        Text("Content")
            .navigationTitle(Localization.title)
    }
}

/// Constants
///
private extension AnalyticsHubView {
    struct Localization {
        static let title = NSLocalizedString("Analytics", comment: "Title for the Analytics Hub screen.")
    }
}

// MARK: Preview

struct AnalyticsHubPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalyticsHubView()
        }
    }
}
