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

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isRedacted: Bool

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
            .font(.subheadline.bold())
            .foregroundColor(Color(.text))
            .padding(.bottom, Layout.tableSpacing)

            // Rows
            ForEach(rows.indexed(), id: \.0.self) { index, row in
                Button {
                    row.tapHandler?()
                } label: {
                    // Do not render the divider for the last row.
                    TopPerformersRow(data: row, showDivider: index < rows.count - 1)
                }
                .disabled(row.tapHandler == nil)
            }
            .redacted(reason: isRedacted ? .placeholder : [])
            .shimmering(active: isRedacted)
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

        /// Image placeholder.
        ///
        let placeHolder = UIImage.productPlaceholderImage

        /// Item name or title.
        ///
        let name: String

        /// Text displayed under the item name.
        ///
        let details: String

        /// Item Value
        ///
        let value: String

        /// Handles the tap action if the row is tappable. If the row is not tappable, `nil` is set.
        let tapHandler: (() -> Void)?

        init(imageURL: URL? = nil, name: String, details: String, value: String, tapHandler: (() -> Void)? = nil) {
            self.imageURL = imageURL
            self.name = name
            self.details = details
            self.value = value
            self.tapHandler = tapHandler
        }
    }

    /// Row  information to display.
    ///
    let data: Data

    /// Indicates if the bottom divider should be displayed
    ///
    let showDivider: Bool

    var body: some View {
        AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .top) {
            // Image
            KFImage(data.imageURL)
                .placeholder { Image(uiImage: data.placeHolder).foregroundColor(Color(.listIcon)) }
                .resizable()
                .frame(width: imageWidth, height: imageWidth)
                .cornerRadius(Layout.imageCornerRadius)

            // Text Labels + Value + Divider
            VStack {
                // Text Labels + Value
                HStack(alignment: .firstTextBaseline) {
                    // Text Labels
                    VStack(alignment: .leading, spacing: Layout.textSpacing) {
                        Text(data.name)
                            .bodyStyle()
                        Text(data.details)
                            .subheadlineStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Count
                    Text(data.value)
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()
                }

                Divider()
                    .renderedIf(showDivider)
            }
        }
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
                          ],
                          isRedacted: false)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
