import SwiftUI
import StoreDesignSystem
import WooFoundation
import struct Yosemite.WooShippingServiceStatusNotice

/// Carrier service incidents reported by WooCommerce Shipping, one banner per notice in API order.
struct WooShippingServiceStatusNoticesView: View {
    let notices: [WooShippingServiceStatusNotice]
    let onDismiss: (_ noticeID: String) -> Void

    @State private var statusPageURL: URL?

    var body: some View {
        VStack(spacing: StoreSpacing.s3) {
            ForEach(notices, id: \.id) { notice in
                banner(for: notice)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)),
                                            removal: .opacity))
            }
        }
        .safariSheet(url: $statusPageURL)
    }

    private func banner(for notice: WooShippingServiceStatusNotice) -> some View {
        StoreNoticeBanner(notice.message,
                          tone: tone(for: notice),
                          actionTitle: notice.actionURL == nil ? nil : Localization.viewStatusPage,
                          action: notice.actionURL.map { url in { statusPageURL = url } },
                          dismissAccessibilityLabel: String(format: Localization.dismissNotice, notice.message),
                          onDismiss: notice.isDismissible ? { onDismiss(notice.id) } : nil,
                          accessibilityStatus: severityLabel(for: notice))
            .accessibilityIdentifier("wooShipping-service-status-notice-\(notice.id)")
    }

    private func tone(for notice: WooShippingServiceStatusNotice) -> StoreNoticeBannerTone {
        switch notice.severity {
        case .error: .error
        case .warning: .warning
        case .info: .info
        }
    }

    private func severityLabel(for notice: WooShippingServiceStatusNotice) -> String {
        switch notice.severity {
        case .error: Localization.Severity.error
        case .warning: Localization.Severity.warning
        case .info: Localization.Severity.info
        }
    }
}

private extension WooShippingServiceStatusNoticesView {
    enum Localization {
        static let viewStatusPage = NSLocalizedString(
            "wooShipping.createLabels.serviceStatus.viewStatusPage",
            value: "View status page",
            comment: "Button on a carrier service incident banner in the shipping label creation screen that opens the provider status page"
        )
        static let dismissNotice = NSLocalizedString(
            "wooShipping.createLabels.serviceStatus.dismissNotice",
            value: "Dismiss notice: %1$@",
            comment: "Accessibility label for the button that dismisses a carrier service incident banner. " +
            "%1$@ is the incident message, e.g. 'UPS: Label creation delays'."
        )

        enum Severity {
            static let error = NSLocalizedString(
                "wooShipping.createLabels.serviceStatus.severity.error",
                value: "Error",
                comment: "Accessibility description of the severity of a carrier service incident banner on the shipping label creation screen"
            )
            static let warning = NSLocalizedString(
                "wooShipping.createLabels.serviceStatus.severity.warning",
                value: "Warning",
                comment: "Accessibility description of the severity of a carrier service incident banner on the shipping label creation screen"
            )
            static let info = NSLocalizedString(
                "wooShipping.createLabels.serviceStatus.severity.info",
                value: "Information",
                comment: "Accessibility description of the severity of a carrier service incident banner on the shipping label creation screen"
            )
        }
    }
}

#if DEBUG
#Preview("Multiple notices") {
    WooShippingServiceStatusNoticesView(notices: [
        WooShippingServiceStatusNotice(id: "usps",
                                       severity: .error,
                                       message: "USPS: API Outage | Status: Investigating",
                                       isDismissible: false,
                                       actionURL: URL(string: "https://www.easypoststatus.com")),
        WooShippingServiceStatusNotice(id: "ups",
                                       severity: .warning,
                                       message: "UPS: Label creation delays | Status: Monitoring",
                                       isDismissible: true,
                                       actionURL: nil),
        WooShippingServiceStatusNotice(id: "dhl",
                                       severity: .info,
                                       message: "DHL Express: Scheduled maintenance tonight",
                                       isDismissible: true,
                                       actionURL: URL(string: "https://www.easypoststatus.com"))
    ], onDismiss: { _ in })
    .padding()
}

#Preview("Single notice") {
    WooShippingServiceStatusNoticesView(notices: [
        WooShippingServiceStatusNotice(id: "usps",
                                       severity: .warning,
                                       message: "USPS: API Degradation | Status: Investigating",
                                       isDismissible: false,
                                       actionURL: URL(string: "https://www.easypoststatus.com"))
    ], onDismiss: { _ in })
    .padding()
}
#endif
