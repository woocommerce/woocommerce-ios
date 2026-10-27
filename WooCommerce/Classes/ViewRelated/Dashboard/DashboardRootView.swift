import Experiments
import SwiftUI
import enum Yosemite.StatsTimeRangeV4
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask
import struct Yosemite.Coupon
import struct Yosemite.Order

/// Selects the dashboard implementation at the feature-flag boundary.
///
/// Keep this as the only `storeDesignSystem` branch in the dashboard hierarchy so the
/// legacy implementation remains available as an exact rollback path.
struct DashboardRootView: View {
    @ObservedObject private var viewModel: DashboardViewModel

    private let featureFlagService: FeatureFlagService

    /// Set externally in the hosting controller.
    var onboardingTaskTapped: ((Site, StoreOnboardingTask) -> Void)?
    /// Set externally in the hosting controller.
    var viewAllOnboardingTasksTapped: ((Site, [StoreOnboardingTaskViewModel]) -> Void)?

    /// Set externally in the hosting controller.
    var showAllBlazeCampaignsTapped: (() -> Void)?
    /// Set externally in the hosting controller.
    var createBlazeCampaignTapped: ((_ productID: Int64?) -> Void)?

    /// Set externally in the hosting controller.
    var jetpackBenefitsBannerTapped: ((Site) -> Void)?

    /// Set externally in the hosting controller.
    var onCustomRangeRedactedViewTap: (() -> Void)?
    /// Set externally in the hosting controller.
    var onViewAllAnalytics: ((_ siteID: Int64,
                              _ timeZone: TimeZone,
                              _ timeRange: StatsTimeRangeV4) -> Void)?
    /// Set externally in the hosting controller.
    var onViewAllCoupons: (() -> Void)?
    /// Set externally in the hosting controller.
    var onViewCouponDetail: ((_ coupon: Coupon) -> Void)?
    /// Set externally in the hosting controller.
    var onShowAllInboxMessages: (() -> Void)?
    /// Set externally in the hosting controller.
    var onViewAllOrders: (() -> Void)?
    /// Set externally in the hosting controller.
    var onViewOrderDetail: ((_ order: Order) -> Void)?
    /// Set externally in the hosting controller.
    var onViewReviewDetail: ((_ review: ReviewViewModel) -> Void)?
    /// Set externally in the hosting controller.
    var onViewAllReviews: (() -> Void)?
    /// Set externally in the hosting controller.
    var onCreateNewGoogleAdsCampaign: (() -> Void)?
    /// Set externally in the hosting controller.
    var onShowAllGoogleAdsCampaigns: (() -> Void)?
    /// Set externally in the hosting controller.
    var onConnectWPComSetup: (() -> Void)?

    init(viewModel: DashboardViewModel,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.viewModel = viewModel
        self.featureFlagService = featureFlagService
    }

    var body: some View {
        if featureFlagService.usesStoreDesignSystem {
            StoreDashboardView(viewModel: viewModel, actions: actions)
        } else {
            legacyContent
        }
    }
}

private extension DashboardRootView {
    var legacyContent: DashboardView {
        var content = DashboardView(viewModel: viewModel)
        content.onboardingTaskTapped = onboardingTaskTapped
        content.viewAllOnboardingTasksTapped = viewAllOnboardingTasksTapped
        content.showAllBlazeCampaignsTapped = showAllBlazeCampaignsTapped
        content.createBlazeCampaignTapped = createBlazeCampaignTapped
        content.jetpackBenefitsBannerTapped = jetpackBenefitsBannerTapped
        content.onCustomRangeRedactedViewTap = onCustomRangeRedactedViewTap
        content.onViewAllAnalytics = onViewAllAnalytics
        content.onViewAllCoupons = onViewAllCoupons
        content.onViewCouponDetail = onViewCouponDetail
        content.onShowAllInboxMessages = onShowAllInboxMessages
        content.onViewAllOrders = onViewAllOrders
        content.onViewOrderDetail = onViewOrderDetail
        content.onViewReviewDetail = onViewReviewDetail
        content.onViewAllReviews = onViewAllReviews
        content.onCreateNewGoogleAdsCampaign = onCreateNewGoogleAdsCampaign
        content.onShowAllGoogleAdsCampaigns = onShowAllGoogleAdsCampaigns
        content.onConnectWPComSetup = onConnectWPComSetup
        return content
    }

    var actions: StoreDashboardActions {
        StoreDashboardActions(
            onboardingTaskTapped: onboardingTaskTapped,
            viewAllOnboardingTasksTapped: viewAllOnboardingTasksTapped,
            showAllBlazeCampaignsTapped: showAllBlazeCampaignsTapped,
            createBlazeCampaignTapped: createBlazeCampaignTapped,
            jetpackBenefitsBannerTapped: jetpackBenefitsBannerTapped,
            customRangeRedactedViewTapped: onCustomRangeRedactedViewTap,
            viewAllAnalyticsTapped: onViewAllAnalytics,
            viewAllCouponsTapped: onViewAllCoupons,
            couponDetailTapped: onViewCouponDetail,
            showAllInboxMessagesTapped: onShowAllInboxMessages,
            viewAllOrdersTapped: onViewAllOrders,
            orderDetailTapped: onViewOrderDetail,
            reviewDetailTapped: onViewReviewDetail,
            viewAllReviewsTapped: onViewAllReviews,
            createGoogleAdsCampaignTapped: onCreateNewGoogleAdsCampaign,
            showAllGoogleAdsCampaignsTapped: onShowAllGoogleAdsCampaigns,
            connectWPComSetupTapped: onConnectWPComSetup
        )
    }
}

#Preview {
    DashboardRootView(viewModel: DashboardViewModel(siteID: 123, usageTracksEventEmitter: .init()))
}
