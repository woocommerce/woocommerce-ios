import StoreDesignSystem
import SwiftUI

struct StoreOrderListHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let state: StoreOrderListHeaderState
    let onFilter: () -> Void
    let onTroubleshoot: () -> Void
    let onContactSupport: () -> Void
    let onRetryCurrency: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s5) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                    StoreOrderListHeaderTitle(state: state)
                    StoreOrderListFilterChip(state: state, action: onFilter)
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: StoreSpacing.s4) {
                        StoreOrderListHeaderTitle(state: state)
                        Spacer(minLength: StoreSpacing.s4)
                        StoreOrderListFilterChip(state: state, action: onFilter)
                    }
                    VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                        StoreOrderListHeaderTitle(state: state)
                        StoreOrderListFilterChip(state: state, action: onFilter)
                    }
                }
            }

            switch state.banner {
            case .none:
                EmptyView()
            case let .error(title, message):
                StoreNoticeBanner(title,
                                  description: message,
                                  tone: .error,
                                  icon: StoreIcon.CircleInfo.regular,
                                  actionTitle: ErrorTopBannerFactory.Localization.contactSupport,
                                  action: onContactSupport,
                                  prominentActionTitle: ErrorTopBannerFactory.Localization.troubleshoot,
                                  prominentAction: onTroubleshoot,
                                  accessibilityStatus: OrderListLocalization.errorAccessibilityStatus)
            case .currencyUnavailable:
                StoreNoticeBanner(OrderListLocalization.currencyUnavailableTitle,
                                  description: OrderListLocalization.currencyUnavailableInfo,
                                  tone: .warning,
                                  icon: StoreIcon.CircleInfo.regular,
                                  actionTitle: OrderListLocalization.currencyUnavailableRetry,
                                  action: onRetryCurrency,
                                  accessibilityStatus: OrderListLocalization.warningAccessibilityStatus)
            }
        }
        .padding(StorePadding.p5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color.storeOnSurface)
        .background {
            if #available(iOS 26.0, *) {
                Color.clear
            } else {
                Color.storeSurface
            }
        }
    }
}

#Preview("All orders") {
    StoreOrderListHeader(state: .init(activeFilterCount: 0,
                                      lastUpdatedText: "Last Updated: 10:30 AM",
                                      banner: .none),
                             onFilter: {},
                             onTroubleshoot: {},
                             onContactSupport: {},
                             onRetryCurrency: {})
}

#Preview("Filtered with error") {
    StoreOrderListHeader(state: .init(activeFilterCount: 3,
                                      lastUpdatedText: "Last Updated: Nov 18, 10:30 AM",
                                      banner: .error(title: "We couldn't load your data",
                                                     message: "Please try again later.")),
                             onFilter: {},
                             onTroubleshoot: {},
                             onContactSupport: {},
                             onRetryCurrency: {})
        .environment(\.dynamicTypeSize, .accessibility3)
}
