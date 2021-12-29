import SwiftUI

// MARK: - AnalyticsView
//
struct AnalyticsView: View {

    let siteID: Int64
    @ObservedObject var viewModel = AnalyticsViewModel()

    var body: some View {
        ZStack {
            VStack {
                DateRangeView(dateRangeText: "Today (Sep 10, 2020)", selectedRange: $viewModel.selectedRange)
                Spacer()
            }
        }
        .navigationTitle(Localization.title)
        .onChange(of: viewModel.selectedRange) { newValue in
            viewModel.saveSelectedDateRange(siteID: siteID, range: newValue)
        }
        .onAppear {
            viewModel.getSelectedDateRange(siteID: siteID)
        }
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView(siteID: 0, viewModel: AnalyticsViewModel())
    }
}

private extension AnalyticsView {
    enum Localization {
        static let title = NSLocalizedString("Analytics", comment: "Title of the analytics view.")
    }
}
