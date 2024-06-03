import SwiftUI
import Yosemite
import enum Networking.DotcomError

/// SwiftUI view for the most active coupons card.
///
struct MostActiveCouponsCard: View {
    @ObservedObject private var viewModel: MostActiveCouponsCardViewModel
    @State private var showingCustomRangePicker = false
    private let onViewAllCoupons: () -> Void
    private let onViewCouponDetail: (_ coupon: Coupon) -> Void
    @State private var showingSupportForm = false

    init(viewModel: MostActiveCouponsCardViewModel,
         onViewAllCoupons: @escaping () -> Void,
         onViewCouponDetail: @escaping (_ coupon: Coupon) -> Void) {
        self.viewModel = viewModel
        self.onViewAllCoupons = onViewAllCoupons
        self.onViewCouponDetail = onViewCouponDetail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            if let error = viewModel.syncingError {
                if error as? DotcomError == .noRestRoute {
                    contentUnavailableView
                        .padding(.horizontal, Layout.padding)
                } else {
                    DashboardCardErrorView(onRetry: {
                        ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .coupons))
                        Task {
                            await viewModel.reloadData()
                        }
                    })
                    .padding(.horizontal, Layout.padding)
                }
            } else {
                timeRangeBar
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                    .shimmering(active: viewModel.syncingData)

                Divider()

                if viewModel.syncingData || viewModel.rows.isNotEmpty {
                    couponsList
                } else {
                    emptyView
                }

                viewAllCouponsButton
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                    .shimmering(active: viewModel.syncingData)
            }
        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
        .sheet(isPresented: $showingCustomRangePicker) {
            RangedDatePicker(startDate: viewModel.startDateForCustomRange,
                             endDate: viewModel.endDateForCustomRange,
                             customApplyButtonTitle: viewModel.buttonTitleForCustomRange,
                             datesSelected: { start, end in
                viewModel.didSelectTimeRange(.custom(from: start, to: end))
            })
        }
        .sheet(isPresented: $showingSupportForm) {
            supportForm
        }
    }
}

private extension MostActiveCouponsCard {
    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(viewModel.syncingError != nil)
            Text(DashboardCard.CardType.coupons.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    viewModel.dismiss()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, Layout.padding)
                    .padding(.vertical, Layout.hideIconVerticalPadding)
            }
            .disabled(viewModel.syncingData)
        }
    }

    var couponsList: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            // Header
            HStack {
                Text(Localization.coupons)
                    .fontWeight(.semibold)
                    .subheadlineStyle()
                Spacer()
                Text(Localization.uses)
                    .fontWeight(.semibold)
                    .subheadlineStyle()
            }
            .padding(.horizontal, Layout.padding)

            // Rows
            ForEach(viewModel.rows) { item in
                MostActiveCouponRow(viewModel: item, tapHandler: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .coupons))
                    onViewCouponDetail(item.coupon)
                })
            }
            .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
            .shimmering(active: viewModel.syncingData)
        }
    }

    var emptyView: some View {
        VStack(spacing: 0) {
            MostActiveCouponsEmptyView()
                .frame(maxWidth: .infinity)

            Divider()
        }
    }

    var timeRangeBar: some View {
        HStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                Text(viewModel.timeRange.isCustomTimeRange ?
                     Localization.custom : viewModel.timeRange.tabTitle)
                .foregroundStyle(Color(.text))
                .subheadlineStyle()

                if viewModel.timeRange.isCustomTimeRange {
                    Button {
                        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .coupons))
                        showingCustomRangePicker = true
                    } label: {
                        HStack {
                            Text(viewModel.timeRangeText)
                            Image(systemName: "pencil")
                        }
                        .foregroundStyle(Color.accentColor)
                        .subheadlineStyle()
                    }
                } else {
                    Text(viewModel.timeRangeText)
                        .subheadlineStyle()
                }
            }
            Spacer()
            StatsTimeRangePicker(currentTimeRange: viewModel.timeRange) { newTimeRange in
                ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .coupons))

                if newTimeRange.isCustomTimeRange {
                    showingCustomRangePicker = true
                } else {
                    viewModel.didSelectTimeRange(newTimeRange)
                }
            }
            .disabled(viewModel.syncingData)
        }
    }

    var viewAllCouponsButton: some View {
        Button {

            ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .coupons))

            onViewAllCoupons()
        } label: {
            HStack {
                Text(Localization.viewAll)
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .disabled(viewModel.syncingData)
    }

    var contentUnavailableView: some View {
        VStack(alignment: .center, spacing: Layout.padding) {
            Image(uiImage: .noStoreImage)
            Text(Localization.ContentUnavailable.title)
                .headlineStyle()
            Text(Localization.ContentUnavailable.details)
                .bodyStyle()
                .multilineTextAlignment(.center)
            Button(Localization.ContentUnavailable.buttonTitle) {
                showingSupportForm = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }

    var supportForm: some View {
        NavigationStack {
            SupportForm(isPresented: $showingSupportForm,
                        viewModel: SupportFormViewModel())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.ContentUnavailable.done) {
                        showingSupportForm = false
                    }
                }
            }
        }
    }
}

private extension MostActiveCouponsCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
    }

    enum Localization {
        static let hideCard = NSLocalizedString(
            "mostActiveCouponsCard.hideCard",
            value: "Hide Coupons",
            comment: "Menu item to dismiss the coupons card on the Dashboard screen"
        )
        static let viewAll = NSLocalizedString(
            "mostActiveCouponsCard.viewAll",
            value: "View all coupons",
            comment: "Button to navigate to Coupons list screen."
        )
        static let custom = NSLocalizedString(
            "mostActiveCouponsCard.custom",
            value: "Custom",
            comment: "Title of the custom time range on the coupons card on the Dashboard screen"
        )
        static let coupons = NSLocalizedString(
            "mostActiveCouponsCard.coupons",
            value: "Coupons",
            comment: "Title in the coupons list on the coupons card on the Dashboard screen"
        )
        static let uses = NSLocalizedString(
            "mostActiveCouponsCard.uses",
            value: "Uses",
            comment: "Title in the coupons list on the coupons card on the Dashboard screen. Denotes the number of times the coupon has been used."
        )
        enum ContentUnavailable {
            static let title = NSLocalizedString(
                "mostActiveCouponsCard.contentUnavailable.title",
                value: "Unable to load coupon usage report",
                comment: "Title when we can't load coupon usage report because user is on a deprecated WooCommerce Version"
            )
            static let details = NSLocalizedString(
                "mostActiveCouponsCard.contentUnavailable.details",
                value: "Make sure you are running the latest version of WooCommerce on your site" +
                " and enabling Analytics in WooCommerce Settings.",
                comment: "Text that explains how to update WooCommerce to get the latest stats"
            )
            static let buttonTitle = NSLocalizedString(
                "mostActiveCouponsCard.contentUnavailable.buttonTitle",
                value: "Still need help? Contact us",
                comment: "Button title to contact support to get help with deprecated stats module"
            )
            static let done = NSLocalizedString(
                "mostActiveCouponsCard.contentUnavailable.dismissSupport",
                value: "Done",
                comment: "Button to dismiss the support form from the Dashboard stats error screen."
            )
        }
    }
}

#Preview {
    MostActiveCouponsCard(viewModel: .init(siteID: 123),
                          onViewAllCoupons: {},
                          onViewCouponDetail: { _ in })
}
