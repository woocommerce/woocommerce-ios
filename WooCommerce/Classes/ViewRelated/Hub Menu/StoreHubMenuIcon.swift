import StoreDesignSystem
import SwiftUI

/// A More tab icon that preserves branded artwork while using Store Design System icons for standard actions.
struct StoreHubMenuIcon: View {
    let item: HubMenuItem

    var body: some View {
        switch item.id {
        case HubMenuViewModel.Blaze.id, HubMenuViewModel.GoogleAds.id:
            StoreIconContainer(
                Image(uiImage: item.icon).renderingMode(.original),
                size: .small,
                tone: .sandstone
            )
        default:
            StoreIconContainer(icon, tone: .sandstone)
        }
    }

    private var icon: StoreIconImage {
        switch item.id {
        case HubMenuViewModel.Settings.id:
            StoreIcon.Gear.regular
        case HubMenuViewModel.Payments.id:
            StoreIcon.CreditCard.regular
        case HubMenuViewModel.Bookings.id:
            StoreIcon.Calendar.regular
        case HubMenuViewModel.WoocommerceAdmin.id:
            StoreIcon.Gauge.regular
        case HubMenuViewModel.ViewStore.id:
            StoreIcon.Store.regular
        case HubMenuViewModel.Coupons.id:
            StoreIcon.Tag.regular
        case HubMenuViewModel.Reviews.id:
            StoreIcon.Star.regular
        case HubMenuViewModel.Inbox.id:
            StoreIcon.Inbox.regular
        case HubMenuViewModel.Customers.id:
            StoreIcon.UserGroup.regular
        default:
            StoreIcon.Ellipsis.regular
        }
    }
}
