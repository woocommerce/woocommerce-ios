import UIKit
import SwiftUI
import Kingfisher

/// View that displays a collection of top items organized in a list.
///
struct TopPerformersView: View {
    /// Indicates what kind of items will be displayed.
    ///
    let itemTitle: String

    /// Indicates what value criteria will be displayed.
    ///
    let valueTitle: String

    /// Items to display.
    ///
    let rows: [TopPerformersRow.Data]

    /// Used to track the text margin value from the top performers row.
    /// Text margin value: Where the row text is placed in the X position.
    /// Needed to properly layout the row divider.
    ///
    @State private var rowTextMargin: CGFloat = 0

    var body: some View {
        VStack() {

            // Header
            HStack {
                Text(itemTitle)
                Spacer()
                Text(valueTitle)
            }
            .foregroundColor(Color(.text))
            .subheadlineStyle()
            .padding(.bottom, Layout.tableSpacing)

            // Rows
            ForEach(rows.indexed(), id: \.0.self) { index, row in

                TopPerformersRow(data: row, textMargin: $rowTextMargin)

                Divider()
                    .padding(.leading, rowTextMargin)
                    .renderedIf(index < rows.count - 1) // Do not render the divider for the last row.
            }
        }
    }
}

/// View that displays one top performer row..
///
struct TopPerformersRow: View {

    /// Dynamic image width, also used for its height.
    ///
    @ScaledMetric var imageWidth = Layout.standardImageWidth

    /// Type that encapsulates dependencies.
    ///
    struct Data {
        /// Item image URL
        ///
        let imageURL: URL?

        /// Item name or title.
        ///
        let name: String

        /// Text displayed under the item name.
        ///
        let details: String

        /// Item Value
        ///
        let value: String
    }

    /// Row  information to display.
    ///
    let data: Data

    /// Binding variable where we set in what X position the text labels begin, using the main view coordinate space.
    /// Useful for letting consumers know where to layout the row divider.
    ///
    @Binding var textMargin: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            AdaptiveStack(horizontalAlignment: .leading) {

                // Image
                KFImage(data.imageURL)
                    .resizable()
                    .frame(width: imageWidth, height: imageWidth)
                    .cornerRadius(Layout.imageCornerRadius)

                // Text Labels
                VStack(alignment: .leading, spacing: Layout.textSpacing) {
                    Text(data.name)
                        .bodyStyle()
                    Text(data.details)
                        .subheadlineStyle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    // Trick to get the text labels X position relative to the main parent view.
                    GeometryReader() { proxy in
                        Color.clear.task {
                            textMargin = proxy.frame(in: .named(Layout.mainViewCoordinaateSpace)).minX
                        }
                    }
                )
            }

            // Count
            Text(data.value)
                .foregroundColor(Color(.text))
                .subheadlineStyle()
        }
        .coordinateSpace(name: Layout.mainViewCoordinaateSpace)
    }
}

private extension TopPerformersView {
    enum Layout {
        static let tableSpacing: CGFloat = 16
    }
}

private extension TopPerformersRow {
    enum Layout {
        static let standardImageWidth: CGFloat = 40
        static let imageCornerRadius: CGFloat = 4
        static let textSpacing: CGFloat = 2
        static let mainViewCoordinaateSpace = "main-view-cs"
    }
}

// MARK: Previews
struct TopPerformersPreview: PreviewProvider {
    static let imageURL = URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")
    static var previews: some View {
        TopPerformersView(itemTitle: "Products",
                          valueTitle: "Items Sold",
                          rows: [
                            .init(imageURL: imageURL, name: "Tabletop Photos", details: "Net Sales: $1,232", value: "32"),
                            .init(imageURL: imageURL, name: "Kentya Palm", details: "Net Sales: $800", value: "10"),
                            .init(imageURL: imageURL, name: "Love Ficus", details: "Net Sales: $599", value: "5"),
                            .init(imageURL: imageURL, name: "Bird Of Paradise", details: "Net Sales: $23.50", value: "2")
                          ])
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
