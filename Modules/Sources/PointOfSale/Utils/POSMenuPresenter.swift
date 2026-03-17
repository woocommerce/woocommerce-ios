import SwiftUI
import struct WooFoundation.WooAnalyticsEvent

@Observable
final class POSMenuPresenter {
    var showExitPOSModal = false
    var showSupport = false
    var showDocumentation = false
    var showSettings = false
    var showOrders = false
    var showBookings = false
    var showProductRestrictionsModal = false
    var showBarcodeScanningModal = false

    @ViewBuilder
    func menuOptions(featureFlags: POSFeatureFlagProviding,
                     isBookingsEligible: Bool,
                     analytics: POSAnalyticsProviding) -> some View {
        Button {
            analytics.track(.pointOfSaleExitMenuItemTapped)
            self.showExitPOSModal = true
        } label: {
            Label(
                title: { Text(Localization.exitPointOfSale) },
                icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
            )
        }
        .accessibilityIdentifier("pos-exit-menu-item")

        Button {
            analytics.track(.pointOfSaleSettingsMenuItemTapped)
            self.showSettings = true
        } label: {
            Label(
                title: { Text(Localization.settings) },
                icon: { Image(systemName: "gearshape") }
            )
        }

        if featureFlags.isFeatureFlagEnabled(.pointOfSaleHistoricalOrdersi1) {
            Button {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersMenuItemTapped())
                self.showOrders = true
            } label: {
                Label(
                    title: { Text(Localization.orders) },
                    icon: { Image(systemName: "text.document") }
                )
            }
        }

        if featureFlags.isFeatureFlagEnabled(.pointOfSaleBookings) && isBookingsEligible {
            Button {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingsMenuItemTapped())
                self.showBookings = true
            } label: {
                Label(
                    title: { Text(Localization.bookings) },
                    icon: { Image(systemName: "calendar") }
                )
            }
        }
    }

    private enum Localization {
        static let exitPointOfSale = NSLocalizedString(
            "pointOfSale.menu.exit.button.title",
            value: "Exit POS",
            comment: "The title of the menu button to exit Point of Sale."
        )
        static let settings = NSLocalizedString(
            "pointOfSale.menu.settings.button.title",
            value: "Settings",
            comment: "The title of the menu button to access Point of Sale settings."
        )
        static let orders = NSLocalizedString(
            "pointOfSale.menu.orders.button.title",
            value: "Orders",
            comment: "The title of the menu button to access Point of Sale orders."
        )
        static let bookings = NSLocalizedString(
            "pointOfSale.menu.bookings.button.title",
            value: "Bookings",
            comment: "The title of the menu button to access Point of Sale bookings."
        )
    }
}
