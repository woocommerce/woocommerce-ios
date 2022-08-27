import WidgetKit
import SwiftUI
import WooFoundation

/// Main StoreInfo Widget type.
///
struct StoreInfoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StoreInfoWidget", provider: StoreInfoProvider()) { entry in
            StoreInfoView(entry: entry)
        }
        .configurationDisplayName("Store Info")
        .supportedFamilies([.systemMedium])
    }
}

/// StoreInfo Widget View
///
struct StoreInfoView: View {

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
                        .bold()
                        .font(.footnote)
                        .foregroundColor(Color(.textInverted))

                    Spacer()

                    Text(entry.range)
                        .font(.caption)
                        .foregroundColor(Color(.lightText))
                }

                // Revenue & Visitors
                HStack() {
                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text(Localization.revenue)
                            .bold()
                            .font(.caption)
                            .foregroundColor(Color(.lightText))

                        Text(entry.revenue)
                            .foregroundColor(Color(.textInverted))
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text(Localization.visitors)
                            .bold()
                            .font(.caption)
                            .foregroundColor(Color(.lightText))

                        Text(entry.visitors)
                            .foregroundColor(Color(.textInverted))
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Orders & Conversion
                HStack {
                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text(Localization.orders)
                            .bold()
                            .font(.caption)
                            .foregroundColor(Color(.lightText))

                        Text(entry.orders)
                            .foregroundColor(Color(.textInverted))
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text(Localization.conversion)
                            .bold()
                            .font(.caption)
                            .foregroundColor(Color(.lightText))

                        Text(entry.conversion)
                            .foregroundColor(Color(.textInverted))
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                }
            }
            .padding(.horizontal)
        }
    }
}

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
    }
}
