import StoreDesignSystem
import SwiftUI
import Yosemite

/// SwiftUI view for the most active coupons card.
///
struct StoreMostActiveCouponsCard: View {
    @ObservedObject private var viewModel: MostActiveCouponsCardViewModel
    @State private var showingCustomRangePicker = false
    private let onViewAllCoupons: () -> Void
    private let onViewCouponDetail: (_ coupon: Coupon) -> Void

    init(viewModel: MostActiveCouponsCardViewModel,
         onViewAllCoupons: @escaping () -> Void,
         onViewCouponDetail: @escaping (_ coupon: Coupon) -> Void) {
        self.viewModel = viewModel
        self.onViewAllCoupons = onViewAllCoupons
        self.onViewCouponDetail = onViewCouponDetail
    }

    var body: some View {
        StoreDashboardCardSurface {
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                header

                if !viewModel.analyticsEnabled {
                    StoreDashboardUnavailableAnalyticsView(title: Localization.unavailableAnalytics)
                } else if viewModel.syncingError != nil {
                    errorState
                } else {
                    timeRangeBar
                        .padding(.horizontal, StorePadding.p5)
                        .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                        .shimmering(active: viewModel.syncingData)

                    StoreDivider()

                    if viewModel.syncingData || viewModel.rows.isNotEmpty {
                        couponsList
                    } else {
                        StoreMostActiveCouponsEmptyView()
                    }

                    StoreDashboardCardFooterAction(Localization.viewAll,
                                                   isDisabled: viewModel.syncingData,
                                                   action: viewAllCoupons)
                        .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                        .shimmering(active: viewModel.syncingData)
                }
            }
        }
        .sheet(isPresented: $showingCustomRangePicker) {
            RangedDatePicker(startDate: viewModel.startDateForCustomRange,
                             endDate: viewModel.endDateForCustomRange,
                             customApplyButtonTitle: viewModel.buttonTitleForCustomRange,
                             datesSelected: { start, end in
                viewModel.didSelectTimeRange(.custom(from: start, to: end))
            })
        }
    }
}

private extension StoreMostActiveCouponsCard {
    typealias Localization = MostActiveCouponsCard.Localization

    var header: some View {
        StoreDashboardCardHeader(DashboardCard.CardType.coupons.name,
                                 showsError: !viewModel.analyticsEnabled || viewModel.syncingError != nil) {
            StoreDashboardCardOverflowMenu(isDisabled: viewModel.syncingData) {
                Button(Localization.hideCard, action: viewModel.dismiss)
            }
        }
    }

    var couponsList: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s3) {
            HStack {
                Text(Localization.coupons)
                Spacer()
                Text(Localization.uses)
            }
            .storeTextStyle(.bodyMedium.emphasized)
            .foregroundStyle(.storeOnSurface)
            .padding(.horizontal, StorePadding.p5)

            ForEach(viewModel.rows) { item in
                StoreMostActiveCouponRow(viewModel: item, tapHandler: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .coupons))
                    onViewCouponDetail(item.coupon)
                })
            }
            .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
            .shimmering(active: viewModel.syncingData)
        }
        .padding(.vertical, StorePadding.p3)
    }

    var timeRangeBar: some View {
        StoreDashboardDateRangeHeader(
            timeRange: viewModel.timeRange,
            dateText: viewModel.timeRangeText,
            customTitle: Localization.custom,
            isDisabled: viewModel.syncingData,
            accessibilityPrefix: "coupons",
            onSelect: selectTimeRange,
            onEditCustom: editCustomRange
        )
    }

    var errorState: some View {
        StoreDashboardCardErrorView {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .coupons))
            Task { await viewModel.reloadData() }
        }
    }

    func editCustomRange() {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .coupons))
        showingCustomRangePicker = true
    }

    func selectTimeRange(_ newTimeRange: StatsTimeRangeV4) {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .coupons))
        if newTimeRange.isCustomTimeRange {
            showingCustomRangePicker = true
        } else {
            viewModel.didSelectTimeRange(newTimeRange)
        }
    }

    func viewAllCoupons() {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .coupons))
        onViewAllCoupons()
    }
}

#Preview {
    StoreMostActiveCouponsCard(viewModel: .init(siteID: 123),
                          onViewAllCoupons: {},
                          onViewCouponDetail: { _ in })
}
