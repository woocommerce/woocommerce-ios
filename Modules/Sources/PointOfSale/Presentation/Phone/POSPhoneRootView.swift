import SwiftUI

struct POSPhoneRootView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posBookingsEligible) private var isBookingsEligible

    @State private var selectedTab: PhoneTab = .sale

    var body: some View {
        TabView(selection: $selectedTab) {
            POSSaleTabView()
                .tabItem {
                    Label(Localization.sale, systemImage: "creditcard")
                }
                .tag(PhoneTab.sale)

            if featureFlags.isFeatureFlagEnabled(.pointOfSaleHistoricalOrdersi1) {
                POSOrdersView(isPresented: .constant(true))
                    .tabItem {
                        Label(Localization.orders, systemImage: "list.clipboard")
                    }
                    .tag(PhoneTab.orders)
            }

            if featureFlags.isFeatureFlagEnabled(.pointOfSaleBookings),
               isBookingsEligible {
                POSBookingsContainerView(isPresented: .constant(true))
                    .tabItem {
                        Label(Localization.bookings, systemImage: "calendar")
                    }
                    .tag(PhoneTab.bookings)
            }

            POSSettingsView(settingsController: posModel.settingsController)
                .tabItem {
                    Label(Localization.settings, systemImage: "gearshape")
                }
                .tag(PhoneTab.settings)
        }
    }
}

private extension POSPhoneRootView {
    enum PhoneTab: Hashable {
        case sale
        case orders
        case bookings
        case settings
    }

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
