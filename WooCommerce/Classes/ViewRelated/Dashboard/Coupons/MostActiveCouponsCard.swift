import SwiftUI
import Yosemite

/// SwiftUI view for the most active coupons card.
///
struct MostActiveCouponsCard: View {
    @ObservedObject private var viewModel: MostActiveCouponsCardViewModel
    @State private var showingCustomRangePicker = false
    private let onViewAllCoupons: (_ siteID: Int64) -> Void

    init(viewModel: MostActiveCouponsCardViewModel,
         onViewAllCoupons: @escaping (_ siteID: Int64) -> Void) {
        self.viewModel = viewModel
        self.onViewAllCoupons = onViewAllCoupons
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            if viewModel.syncingError != nil {
                DashboardCardErrorView(onRetry: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .coupons))
                    Task {
                        await viewModel.reloadData()
                    }
                })
                .padding(.horizontal, Layout.padding)
            } else {
                timeRangeBar
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                    .shimmering(active: viewModel.syncingData)

                Divider()

                couponsList

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
        .sheet(item: $viewModel.selectedCoupon) { coupon in
            couponDetailView(coupon: coupon)
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
                    .fontWeight(.bold)
                    .subheadlineStyle()
                Spacer()
                Text(Localization.uses)
                    .fontWeight(.bold)
                    .subheadlineStyle()
            }
            .padding(.horizontal, Layout.padding)

            // Rows
            ForEach(viewModel.coupons) { item in
                CouponDashboardRow(coupon: item, tapHandler: {
                    viewModel.didSelectCoupon(item)
                })
            }
            .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
            .shimmering(active: viewModel.syncingData)
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
            onViewAllCoupons(viewModel.siteID)
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

    func couponDetailView(coupon: Coupon) -> some View {
        NavigationView {
            // TODO: 12716 - Check the "More" menu and disable it if needed.
            CouponDetails(viewModel: CouponDetailsViewModel(coupon: coupon))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            viewModel.selectedCoupon = nil
                        }, label: {
                            Image(uiImage: .closeButton)
                                .secondaryBodyStyle()
                        })
                    }
                }
        }
    }
}

private struct CouponDashboardRow: View {
    let coupon: Coupon
    let tapHandler: (() -> Void)

    var body: some View {
        Button {
            tapHandler()
        } label: {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(coupon.code)
                            .bodyStyle()
                        Text(coupon.summary())
                            .subheadlineStyle()
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(coupon.usageCount)")
                            .bodyStyle()
                        Spacer()
                    }
                }
                .padding(.horizontal, MostActiveCouponsCard.Layout.padding)

                Divider()
                    .padding(.leading, MostActiveCouponsCard.Layout.padding)
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
    }
}

#Preview {
    MostActiveCouponsCard(viewModel: .init(siteID: 123),
                          onViewAllCoupons: { _ in})
}
