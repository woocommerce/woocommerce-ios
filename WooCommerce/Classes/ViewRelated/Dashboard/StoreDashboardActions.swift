import Foundation
import enum Yosemite.StatsTimeRangeV4
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask
import struct Yosemite.Coupon
import struct Yosemite.Order

/// Navigation and presentation callbacks owned by `DashboardViewHostingController`.
///
/// Grouping them keeps the design-system content independent from the hosting controller
/// without changing the controller's existing callback interface.
struct StoreDashboardActions {
    let onboardingTaskTapped: ((Site, StoreOnboardingTask) -> Void)?
    let viewAllOnboardingTasksTapped: ((Site, [StoreOnboardingTaskViewModel]) -> Void)?
    let showAllBlazeCampaignsTapped: (() -> Void)?
    let createBlazeCampaignTapped: ((Int64?) -> Void)?
    let jetpackBenefitsBannerTapped: ((Site) -> Void)?
    let customRangeRedactedViewTapped: (() -> Void)?
    let viewAllAnalyticsTapped: ((Int64, TimeZone, StatsTimeRangeV4) -> Void)?
    let viewAllCouponsTapped: (() -> Void)?
    let couponDetailTapped: ((Coupon) -> Void)?
    let showAllInboxMessagesTapped: (() -> Void)?
    let viewAllOrdersTapped: (() -> Void)?
    let orderDetailTapped: ((Order) -> Void)?
    let reviewDetailTapped: ((ReviewViewModel) -> Void)?
    let viewAllReviewsTapped: (() -> Void)?
    let createGoogleAdsCampaignTapped: (() -> Void)?
    let showAllGoogleAdsCampaignsTapped: (() -> Void)?
    let connectWPComSetupTapped: (() -> Void)?
}
