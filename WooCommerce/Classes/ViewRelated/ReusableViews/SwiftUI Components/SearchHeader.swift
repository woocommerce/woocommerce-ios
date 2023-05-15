import SwiftUI

/// Search Header View
///
struct SearchHeader: View {
    /// Customizations for the search header component.
    struct Customizations {
        let backgroundColor: UIColor
        let borderColor: UIColor
        let internalHorizontalPadding: CGFloat
        let internalVerticalPadding: CGFloat
        let iconSize: CGSize
    }

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1

    /// Filter search term
    ///
    @Binding private var text: String

    /// Placeholder for the filter text field
    ///
    private let placeholder: String

    private let customizations: Customizations

    private let onEditingChanged: ((Bool) -> Void)?

    /// - Parameters:
    ///   - text: Search term binding.
    ///   - placeholder: Placeholder for the text field.
    ///   - customizations: Customizations of the view styles.
    init(text: Binding<String>,
         placeholder: String,
         onEditingChanged: ((Bool) -> Void)? = nil,
         customizations: Customizations = .init(
            backgroundColor: .searchBarBackground,
            borderColor: .clear,
            internalHorizontalPadding: Layout.internalPadding,
            internalVerticalPadding: Layout.internalPadding,
            iconSize: Layout.iconSize
         )) {
             self._text = text
             self.placeholder = placeholder
             self.onEditingChanged = onEditingChanged
             self.customizations = customizations
         }

    var body: some View {
        HStack(spacing: 0) {
            // Search Icon
            Image(uiImage: .searchBarButtonItemImage)
                .renderingMode(.template)
                .resizable()
                .frame(width: customizations.iconSize.width * scale,
                       height: customizations.iconSize.height * scale)
                .foregroundColor(Color(.listSmallIcon))
                .padding([.leading, .trailing], customizations.internalHorizontalPadding)
                .accessibilityHidden(true)

            // TextField
            TextField(placeholder, text: $text, onEditingChanged: onEditingChanged ?? { _ in })
                .padding([.bottom, .top], customizations.internalVerticalPadding)
                .padding(.trailing, customizations.internalHorizontalPadding)
                .accessibility(addTraits: .isSearchField)
        }
        .background(Color(customizations.backgroundColor))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(customizations.borderColor), style: StrokeStyle(lineWidth: 1))
        )
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

struct SearchHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Default styles.
            SearchHeader(text: .constant("pineapple"), placeholder: "Search fruits")
            // Domain selector styles.
            SearchHeader(text: .constant("papaya"),
                         placeholder: "Search fruits",
                         customizations: .init(backgroundColor: .clear,
                                               borderColor: .separator,
                                               internalHorizontalPadding: 21,
                                               internalVerticalPadding: 12, iconSize: .init(width: 14, height: 14)))
        }
    }
}
