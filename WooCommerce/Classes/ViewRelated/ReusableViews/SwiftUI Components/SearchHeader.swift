import SwiftUI

/// Search Header View
///
struct SearchHeader: View {

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1

    /// Filter search term
    ///
    @Binding var filterText: String

    /// Placeholder for the filter text field
    ///
    let filterPlaceholder: String

    var body: some View {
        HStack(spacing: 0) {
            // Search Icon
            Image(uiImage: .searchBarButtonItemImage)
                .renderingMode(.template)
                .resizable()
                .frame(width: Layout.iconSize.width * scale, height: Layout.iconSize.height * scale)
                .foregroundColor(Color(.listSmallIcon))
                .padding([.leading, .trailing], Layout.internalPadding)

            // TextField
            TextField(filterPlaceholder, text: $filterText)
                .padding([.bottom, .top], Layout.internalPadding)
        }
        .background(Color(.searchBarBackground))
        .cornerRadius(Layout.cornerRadius)
        .padding(Layout.externalPadding)
    }
}

// MARK: Constants

private extension SearchHeader {
    enum Layout {
        static let iconSize = CGSize(width: 16, height: 16)
        static let internalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 10
        static let externalPadding = EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
    }
}
