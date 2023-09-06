import SwiftUI
import enum Yosemite.ProductVariationsSortOrder

/// Hosting controller for `ProductVariationSortOptionView`.
///
final class ProductVariationSortOptionHostingController: UIHostingController<ProductVariationSortOptionView> {
    init(initialOption: ProductVariationsSortOrder,
         onCompletion: @escaping (ProductVariationsSortOrder) -> Void) {
        super.init(rootView: ProductVariationSortOptionView(initialOption: initialOption, onCompletion: onCompletion))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View for selecting sort order for product variation list.
///
struct ProductVariationSortOptionView: View {

    @State private var selectedOption: ProductVariationsSortOrder
    private let onCompletion: (ProductVariationsSortOrder) -> Void

    init(initialOption: ProductVariationsSortOrder,
         onCompletion: @escaping (ProductVariationsSortOrder) -> Void) {
        self.selectedOption = initialOption
        self.onCompletion = onCompletion
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            // title
            Text(Localization.sortBy)
                .captionStyle()

            // options
            ForEach(ProductVariationsSortOrder.allCases, id: \.rawValue) { option in
                HStack {
                    Text(option.displayName)
                        .bodyStyle()
                    Spacer()
                    Image(systemName: "checkmark")
                        .bodyStyle()
                        .foregroundColor(.accentColor)
                        .renderedIf(selectedOption == option)
                }
                .onTapGesture {
                    selectedOption = option
                    onCompletion(option)
                }
            }
        }
        .padding()
    }
}

extension ProductVariationSortOptionView {
    enum Layout {
        static let verticalSpacing: CGFloat = 8
    }
    enum Localization {
        static let sortBy = NSLocalizedString("Sort by", comment: "Text to display on the sort option view for product variations")
    }
}

extension ProductVariationsSortOrder {
    var displayName: String {
        switch self {
        case .dateAscending:
            return Localization.dateAscending
        case .dateDescending:
            return Localization.dateDescending
        case .nameAscending:
            return Localization.nameAscending
        case .nameDescending:
            return Localization.nameDescending
        }
    }

    enum Localization {
        static let dateAscending = NSLocalizedString(
            "Date: Oldest to Newest",
            comment: "Option to sort product variations from the oldest to the newest"
        )
        static let dateDescending = NSLocalizedString(
            "Date: Newest to Oldest",
            comment: "Option to sort product variations from the newest to the oldest"
        )
        static let nameAscending = NSLocalizedString(
            "Title: A to Z",
            comment: "Option to sort product variations by ascending variation name"
        )
        static let nameDescending = NSLocalizedString(
            "Title: Z to A",
            comment: "Option to sort product variations by descending variation name"
        )
    }
}

struct ProductVariationSortOptionView_Previews: PreviewProvider {
    static var previews: some View {
        ProductVariationSortOptionView(initialOption: .dateDescending) { _ in }
    }
}
