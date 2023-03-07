import SwiftUI
import WidgetKit

/// Entry point for StoreInfo Home Screen Widget
///
struct StoreInfoHomescreenWidget: View {
    // Entry to render
    let entry: StoreInfoEntry

    var body: some View {
        switch entry {
        case .notConnected:
            NotLoggedInView()
        case .error:
            UnableToFetchView()
        case .data(let data):
            StoreInfoView(entryData: data)
        }
    }
}

/// StoreInfo Widget View
///
private struct StoreInfoView: View {
    // Stats data to render
    let entryData: StoreInfoData

    // Current size category
    @Environment(\.sizeCategory) var category

    var accessibilityCategory: ContentSizeCategory {
        return .extraLarge
    }

    var body: some View {
        ZStack {
            // Background
            Color(.brand)

            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                    // Store Name
                    HStack {
                        Text(entryData.name)
                            .storeNameStyle()
                        Spacer()
                        Text(entryData.range)
                            .statRangeStyle()
                    }
                    // Updated at
                    Text(Localization.updatedAt(entryData.updatedTime))
                        .statRangeStyle()
                }

                if category > accessibilityCategory {
                    AccessibilityStatsCard(entryData: entryData)
                } else {
                    StatsCard(entryData: entryData)
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Stats card sub view.
/// To be used inside `StoreInfoView`.
///
private struct StatsCard: View {
    // Stats data to render
    let entryData: StoreInfoData

    var body: some View {
        Group {
            // Revenue & Visitors
            HStack() {
                VStack(alignment: .leading, spacing: StoreInfoView.Layout.cardSpacing) {
                    Text(StoreInfoView.Localization.revenue)
                        .statTitleStyle()

                    Text(entryData.revenue)
                        .statValueStyle()

                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: StoreInfoView.Layout.cardSpacing) {
                    Text(StoreInfoView.Localization.visitors)
                        .statTitleStyle()

                    Text(entryData.visitors)
                        .statValueStyle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Orders & Conversion
            HStack {
                VStack(alignment: .leading, spacing: StoreInfoView.Layout.cardSpacing) {
                    Text(StoreInfoView.Localization.orders)
                        .statTitleStyle()

                    Text(entryData.orders)
                        .statValueStyle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: StoreInfoView.Layout.cardSpacing) {
                    Text(StoreInfoView.Localization.conversion)
                        .statTitleStyle()

                    Text(entryData.conversion)
                        .statValueStyle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Accessibility card sub view. Shows only revenue and a `View More` button.
/// To be used inside `StoreInfoView`.
///
private struct AccessibilityStatsCard: View {
    // Stats data to render
    let entryData: StoreInfoData

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: StoreInfoView.Layout.cardSpacing) {
                Text(StoreInfoView.Localization.revenue)
                    .statTitleStyle()

                Text(entryData.revenue)
                    .statValueStyle()
            }

            Text(StoreInfoView.Localization.viewMore)
                .statButtonStyle()
        }
    }
}

private struct NotLoggedInView: View {
    var body: some View {
        ZStack {
            // Background
            Color(.brand)

            VStack {
                Image(uiImage: .wooLogoWhite)
                    .resizable()
                    .frame(width: Layout.logoSize.width, height: Layout.logoSize.height)

                Spacer()

                Text(Localization.notLoggedIn)
                    .statTextStyle()

                Spacer()

                Text(Localization.login)
                    .statButtonStyle()
            }
            .padding(.vertical, Layout.cardVerticalPadding)
        }
    }
}

private struct UnableToFetchView: View {
    var body: some View {
        ZStack {
            // Background
            Color(.brand)

            VStack {
                Image(uiImage: .wooLogoWhite)
                    .resizable()
                    .frame(width: Layout.logoSize.width, height: Layout.logoSize.height)

                Spacer()

                Text(Localization.unableToFetch)
                    .statTextStyle()

                Spacer()
            }
            .padding(.vertical, Layout.cardVerticalPadding)
        }
    }
}

// MARK: - Constants

/// Constants definition
///
private extension StoreInfoView {
    enum Localization {
        static let revenue = AppLocalizedString(
            "storeWidgets.infoView.revenue",
            value: "Revenue",
            comment: "Revenue title label for the store info widget"
        )
        static let visitors = AppLocalizedString(
            "storeWidgets.infoView.visitors",
            value: "Visitors",
            comment: "Visitors title label for the store info widget"
        )
        static let orders = AppLocalizedString(
            "storeWidgets.infoView.orders",
            value: "Orders",
            comment: "Orders title label for the store info widget"
        )
        static let conversion = AppLocalizedString(
            "storeWidgets.infoView.conversion",
            value: "Conversion",
            comment: "Conversion title label for the store info widget"
        )
        static let viewMore = AppLocalizedString(
            "storeWidgets.infoView.viewMore",
            value: "View More",
            comment: "Title for the button indicator to display more stats in the Today's Stat widget when using accessibility fonts."
        )
        static func updatedAt(_ updatedTime: String) -> LocalizedString {
            let format = AppLocalizedString("storeWidgets.infoView.updatedAt",
                                            value: "As of %1$@",
                                            comment: "Displays the time when the widget was last updated. %1$@ is the time to render.")
            return LocalizedString.localizedStringWithFormat(format, updatedTime)
        }
    }

    enum Layout {
        static let sectionSpacing = 8.0
        static let cardSpacing = 2.0
    }
}

/// Constants definition
///
private extension NotLoggedInView {
    enum Localization {
        static let notLoggedIn = AppLocalizedString(
            "storeWidgets.notLoggedInView.notLoggedIn",
            value: "Log in to see today’s stats.",
            comment: "Title label when the widget does not have a logged-in store."
        )
        static let login = AppLocalizedString(
            "storeWidgets.notLoggedInView.login",
            value: "Log in",
            comment: "Title label for the login button on the store info widget."
        )
    }

    enum Layout {
        static let cardVerticalPadding = 22.0
        static let logoSize = CGSize(width: 24, height: 16)
    }
}

/// Constants definition
///
private extension UnableToFetchView {
    enum Localization {
        static let unableToFetch = AppLocalizedString(
            "storeWidgets.unableToFetchView.unableToFetch",
            value: "Unable to fetch today's stats",
            comment: "Title label when the widget can't fetch data."
        )
    }

    enum Layout {
        static let cardVerticalPadding = 22.0
        static let logoSize = CGSize(width: 24, height: 16)
    }
}

// MARK: - Previews

struct StoreWidgets_Previews: PreviewProvider {
    static var exampleData = StoreInfoData(range: "Today",
                                           name: "Ernest Shop",
                                           revenue: "$132.234",
                                           revenueCompact: "$132",
                                           visitors: "67",
                                           orders: "23",
                                           conversion: "34%",
                                           updatedTime: "10:24 PM")

    static var previews: some View {
        StoreInfoView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))

        StoreInfoView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.sizeCategory, .extraExtraLarge)
            .previewDisplayName("XXL font")

        NotLoggedInView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Not logged in")

        UnableToFetchView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Unable to fetch data")
    }
}
