import WidgetKit
import SwiftUI
import WooFoundation
import Experiments

/// Main StoreInfo Widget type.
///
struct StoreInfoWidget: Widget {

    let enableWidgets = DefaultFeatureFlagService().isFeatureFlagEnabled(.storeWidgets)

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StoreInfoWidget", provider: StoreInfoProvider()) { entry in
            StoreInfoView(entry: entry)
        }
        .configurationDisplayName("Store Info")
        .supportedFamilies(enableWidgets ? [.systemMedium] : [])
    }
}

/// StoreInfo Widget View
///
private struct StoreInfoView: View {

    // Entry to render
    let entry: StoreInfoEntry

    var body: some View {
        ZStack {
            // Background
            Color(.brand)

            VStack(spacing: Layout.sectionSpacing) {

                // Store Name
                HStack {
                    Text(entry.name)
                        .storeNameStyle()

                    Spacer()

                    Text(entry.range)
                        .statRangeStyle()
                }

                // Revenue & Visitors
                HStack() {
                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text(Localization.revenue)
                            .statTitleStyle()

                        Text(entry.revenue)
                            .statValueStyle()

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text(Localization.visitors)
                            .statTitleStyle()

                        Text(entry.visitors)
                            .statValueStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Orders & Conversion
                HStack {
                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text(Localization.orders)
                            .statTitleStyle()

                        Text(entry.orders)
                            .statValueStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text(Localization.conversion)
                            .statTitleStyle()

                        Text(entry.conversion)
                            .statValueStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal)
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

// MARK: Constants

/// Constants definition
///
private extension StoreInfoView {
    enum Localization {
        static let revenue = NSLocalizedString("Revenue", comment: "Revenue title label for the store info widget")
        static let visitors = NSLocalizedString("Visitors", comment: "Visitors title label for the store info widget")
        static let orders = NSLocalizedString("Orders", comment: "Orders title label for the store info widget")
        static let conversion = NSLocalizedString("Conversion", comment: "Conversion title label for the store info widget")
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
        static let notLoggedIn = NSLocalizedString("Log in to see today’s stats.",
                                                   comment: "Title label when the widget does not have a logged-in store.")
        static let login = NSLocalizedString("Log in",
                                             comment: "Title label for the login button on the store info widget.")
    }

    enum Layout {
        static let cardVerticalPadding = 22.0
        static let logoSize = CGSize(width: 24, height: 16)
    }
}

// MARK: Previews

struct StoreWidgets_Previews: PreviewProvider {
    static var previews: some View {
        StoreInfoView(
            entry: StoreInfoEntry(date: Date(),
                                  range: "Today",
                                  name: "Ernest Shop",
                                  revenue: "$132.234",
                                  visitors: "67",
                                  orders: "23",
                                  conversion: "37%")
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))

        NotLoggedInView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
