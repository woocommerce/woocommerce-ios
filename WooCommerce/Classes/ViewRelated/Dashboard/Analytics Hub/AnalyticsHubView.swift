import Foundation
import Yosemite
import SwiftUI

/// Hosting Controller for the `AnalyticsHubView` view.
///
final class AnalyticsHubHostingViewController: UIHostingController<AnalyticsHubView> {
    init(timeRange: AnalyticsHubTimeRange) {
        super.init(rootView: AnalyticsHubView(timeRange))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Main Analytics Hub View
///
struct AnalyticsHubView: View {
    private var timeRange: AnalyticsHubTimeRange

    init(_ timeRange: AnalyticsHubTimeRange) {
        self.timeRange = timeRange
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.vertialSpacing) {
                VStack(spacing: 0) {
                    Divider()
                    VStack {
                        Text(timeRange.selectionType.rawValue)
                        Text(timeRange.currentRangeDescription)
                        Divider()
                        Text(timeRange.previousRangeDescription)

                    }
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
        static let vertialSpacing: CGFloat = 24.0
    }
}

// MARK: Preview

struct AnalyticsHubPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            let timeRange = AnalyticsHubTimeRange(selectedTimeRange: .thisMonth)
            AnalyticsHubView(timeRange)
        }
    }
}
