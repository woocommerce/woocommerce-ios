import StoreDesignSystem
import SwiftUI

struct StoreOrderListBanner: View {
    let banner: OrderListViewModel.TopBanner
    let onRetryCurrency: () -> Void
    let onTroubleshoot: (Error) -> Void
    let onContactSupport: () -> Void

    var body: some View {
        switch banner {
        case .none:
            EmptyView()
        case .currencyUnavailable:
            StoreNoticeBanner(OrderListLocalization.currencyUnavailableTitle,
                              description: OrderListLocalization.currencyUnavailableInfo,
                              tone: .warning,
                              icon: StoreIcon.CircleInfo.regular,
                              actionTitle: OrderListLocalization.currencyUnavailableRetry,
                              action: onRetryCurrency,
                              accessibilityStatus: Localization.warning)
                .padding(.horizontal, StorePadding.p5)
                .padding(.vertical, StorePadding.p3)
        case .error(let error):
            VStack(alignment: .trailing, spacing: StoreSpacing.s3) {
                StoreNoticeBanner(errorType(for: error).title,
                                  description: errorType(for: error).info,
                                  tone: .error,
                                  icon: StoreIcon.CircleInfo.regular,
                                  actionTitle: ErrorTopBannerFactory.Localization.troubleshoot,
                                  action: { onTroubleshoot(error) },
                                  accessibilityStatus: Localization.error)
                StoreButton(ErrorTopBannerFactory.Localization.contactSupport,
                            variant: .outlined,
                            action: onContactSupport)
            }
            .padding(.horizontal, StorePadding.p5)
            .padding(.vertical, StorePadding.p3)
        }
    }

    private func errorType(for error: Error) -> ErrorTopBannerFactory.ErrorType {
        ErrorTopBannerFactory.ErrorType(error: error)
    }
}

private extension StoreOrderListBanner {
    enum Localization {
        static let warning = NSLocalizedString(
            "orderList.storeNoticeBanner.warning.accessibilityStatus",
            value: "Warning",
            comment: "VoiceOver severity announced for a warning banner on the Orders list."
        )
        static let error = NSLocalizedString(
            "orderList.storeNoticeBanner.error.accessibilityStatus",
            value: "Error",
            comment: "VoiceOver severity announced for an error banner on the Orders list."
        )
    }
}
