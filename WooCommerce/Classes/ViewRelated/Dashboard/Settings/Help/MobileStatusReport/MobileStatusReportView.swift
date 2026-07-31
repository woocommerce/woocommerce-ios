import SwiftUI
import protocol WooFoundation.Analytics

/// Hosting controller wrapper for `MobileStatusReportView`.
///
final class MobileStatusReportHostingController: TabBarHidingHostingController<MobileStatusReportView> {

    init() {
        super.init(rootView: MobileStatusReportView())
        rootView.noticePresenter.presentingViewController = self
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Displays the Mobile Status Report — the same report attached to support tickets.
///
/// Deliberately not built on `SystemStatusReportView`: that screen exists to fetch a report from the store, so
/// most of it is loading, retry and error handling. This report is generated on device and cannot fail, and
/// bending the other screen around that would leave both harder to follow.
///
struct MobileStatusReportView: View {

    /// Notice presenter to present the successful copy message.
    ///
    let noticePresenter: DefaultNoticePresenter

    @State private var report: String = ""

    private let reportProvider: MobileStatusReportProvider
    private let analytics: Analytics

    init(reportProvider: MobileStatusReportProvider = MobileStatusReportProvider(),
         analytics: Analytics = ServiceLocator.analytics) {
        self.reportProvider = reportProvider
        self.analytics = analytics
        self.noticePresenter = DefaultNoticePresenter()
    }

    var body: some View {
        Group {
            if report.isEmpty {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            } else {
                ScrollView {
                    Text(report)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .navigationTitle(Localization.title)
        .task {
            report = await reportProvider.generateReport()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: report) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(report.isEmpty)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIPasteboard.general.string = report
                    noticePresenter.enqueue(notice: Notice(title: Localization.copiedToClipboard, feedbackType: .success))
                    analytics.track(.supportMobileStatusReportCopyButtonTapped)
                } label: {
                    Image(uiImage: .copyBarButtonItemImage)
                        .renderingMode(.template)
                        .flipsForRightToLeftLayoutDirection(true)
                }
                .disabled(report.isEmpty)
            }
        }
        .wooNavigationBarStyle()
    }
}

private extension MobileStatusReportView {
    enum Localization {
        static let title = NSLocalizedString(
            "mobileStatusReportView.title",
            value: "Mobile Status Report",
            comment: "Navigation title of the mobile status report screen"
        )
        static let copiedToClipboard = NSLocalizedString(
            "mobileStatusReportView.copiedToClipboard",
            value: "Mobile status report copied to clipboard",
            comment: "Toast message shown after tapping Copy on the Mobile Status Report screen"
        )
    }
}

#Preview {
    NavigationStack {
        MobileStatusReportView()
    }
}
