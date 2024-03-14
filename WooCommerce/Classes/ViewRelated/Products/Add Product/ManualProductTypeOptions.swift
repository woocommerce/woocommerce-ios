import SwiftUI

/// View to show the manual product type creation options.
///
struct ManualProductTypeOptions: View {
    private let productTypes: [BottomSheetProductType]
    private let onOptionSelected: (BottomSheetProductType) -> Void

    /// Grouped product types based on their product category
    private let groupedProductTypes: [(ProductCreationCategory, [BottomSheetProductType])]

    init(productTypes: [BottomSheetProductType],
         onOptionSelected: @escaping (BottomSheetProductType) -> Void) {
        self.productTypes = productTypes
        self.onOptionSelected = onOptionSelected

        self.groupedProductTypes = Constants.productCategoriesOrder.compactMap { category in
            let currentCategoryProductTypes = productTypes.filter { $0.productCreationCategory == category }
            return currentCategoryProductTypes.isEmpty ? nil : (category, currentCategoryProductTypes)
        }
    }

    var body: some View {
        ForEach(groupedProductTypes, id: \.0) { (category, productTypes) in
            VStack {
                Text(category.description)
                    .subheadlineStyle()
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Constants.categoryVerticalSpacing)
                    .padding(.horizontal, Constants.horizontalSpacing)

                ForEach(productTypes, id: \.self) { productType in
                    HStack(alignment: .top, spacing: Constants.margin) {
                        Image(uiImage: productType.actionSheetImage.withRenderingMode(.alwaysTemplate))
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .padding(.top, Constants.productIconTopSpacing)

                        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                            Text(productType.actionSheetTitle)
                                .bodyStyle()
                            Text(productType.actionSheetDescription)
                                .subheadlineStyle()
                        }
                        .padding(.bottom, Constants.productBottomSpacing)
                        Spacer()
                    }
                    .padding(.horizontal, Constants.horizontalSpacing)
                    .onTapGesture {
                        onOptionSelected(productType)
                    }

                }
                if category != Constants.productCategoriesOrder.last {
                    Divider()
                        .padding(.vertical, Constants.categoryVerticalSpacing)
                }
            }
        }
    }
}

private extension ManualProductTypeOptions {
    enum Constants {
        // List of product categories. The ordering dictates how the categories are displayed.
        static let productCategoriesOrder: [ProductCreationCategory] = [.standard, .subscription, .other]
        static let verticalSpacing: CGFloat = 4
        static let horizontalSpacing: CGFloat = 16
        static let categoryVerticalSpacing: CGFloat = 8
        static let productBottomSpacing: CGFloat = 16
        static let productIconTopSpacing: CGFloat = 8
        static let margin: CGFloat = 16
    }
}

#Preview {
    ManualProductTypeOptions(
        productTypes: [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .subscription,
            .variable,
            .variableSubscription,
            .grouped,
            .affiliate
        ],
        onOptionSelected: { _ in }
    )
}
