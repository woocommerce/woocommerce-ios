import SwiftUI

struct POSPhoneRootView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posBookingsEligible) private var isBookingsEligible
    @Environment(\.posNavigationModel) private var navigationModel

    var body: some View {
        @Bindable var navModel = navigationModel
        TabView(selection: $navModel.selectedTab) {
            POSSaleTabView()
                .tabItem {
                    Label(Localization.sale, systemImage: "creditcard")
                }
                .tag(POSNavigationModel.Tab.sale)

            if featureFlags.isFeatureFlagEnabled(.pointOfSaleHistoricalOrdersi1) {
                POSOrdersView(isPresented: .constant(true))
                    .tabItem {
                        Label(Localization.orders, systemImage: "list.clipboard")
                    }
                    .tag(POSNavigationModel.Tab.orders)
            }

            if featureFlags.isFeatureFlagEnabled(.pointOfSaleBookings),
               isBookingsEligible {
                POSBookingsContainerView(isPresented: .constant(true))
                    .tabItem {
                        Label(Localization.bookings, systemImage: "calendar")
                    }
                    .tag(POSNavigationModel.Tab.bookings)
            }

            POSSettingsView(settingsController: posModel.settingsController)
                .tabItem {
                    Label(Localization.settings, systemImage: "gearshape")
                }
                .tag(POSNavigationModel.Tab.settings)
        }
    }
}

private extension POSPhoneRootView {
    enum Localization {
        static let sale = NSLocalizedString(
            "pos.phone.tab.sale",
            value: "Sale",
            comment: "Title for the Sale tab in phone POS"
        )
        static let orders = NSLocalizedString(
            "pos.phone.tab.orders",
            value: "Orders",
            comment: "Title for the Orders tab in phone POS"
        )
        static let bookings = NSLocalizedString(
            "pos.phone.tab.bookings",
            value: "Bookings",
            comment: "Title for the Bookings tab in phone POS"
        )
        static let settings = NSLocalizedString(
            "pos.phone.tab.settings",
            value: "Settings",
            comment: "Title for the Settings tab in phone POS"
        )
    }
}
