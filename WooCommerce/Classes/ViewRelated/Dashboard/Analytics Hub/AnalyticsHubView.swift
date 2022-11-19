import Foundation
import SwiftUI

/// Main Analytics Hub View
///
struct AnalyticsHubView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.vertialSpacing) {
                VStack(spacing: 0) {
                    Divider()
                    Text("Placeholder for Revenue Card")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
                        .background(Color(uiColor: .listForeground))

                    Divider()
                }


                VStack(spacing: 0) {
                    Divider()

                    Text("Placeholder For Revenue Card")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
                        .background(Color(uiColor: .listForeground))

                    Divider()
                }

                VStack(spacing: 0) {
                    Divider()

                    Text("Placeholder For Orders Card")
                        .padding(.leading)
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
                        .background(Color(uiColor: .listForeground))

                    Divider()
                }

                Spacer()
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .listBackground))
    }
}

/// Constants
///
private extension AnalyticsHubView {
    struct Localization {
        static let title = NSLocalizedString("Analytics", comment: "Title for the Analytics Hub screen.")
    }

    struct Layout {
        static let vertialSpacing: CGFloat = 26.0
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
