import SwiftUI

/// View to show the manual product type creation options.
///
struct ManualProductTypeOptions: View {
    private let supportedProductTypes: [BottomSheetProductType]
    private let onOptionSelected: (BottomSheetProductType) -> Void

    private let supportedProductCategories: [BottomSheetProductCategory]

    @ScaledMetric private var scale: CGFloat = 1.0

    init(supportedProductTypes: [BottomSheetProductType],
         onOptionSelected: @escaping (BottomSheetProductType) -> Void) {
        self.supportedProductTypes = supportedProductTypes
        self.onOptionSelected = onOptionSelected

        self.supportedProductCategories = BottomSheetProductCategory.allCases.filter { category in
            // Only show a product category if at least one of its product types can be found in `supportedProductTypes`
            category.productTypes.first { supportedProductTypes.contains($0) } != nil
        }
    }

    var body: some View {
        ForEach(supportedProductCategories, id: \.self) { category in
            VStack {
                Text(category.label)
                    .subheadlineStyle()
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Constants.categoryVerticalSpacing)
                    .padding(.horizontal, Constants.horizontalSpacing)

                ForEach(category.productTypes) { productType in
                    if supportedProductTypes.contains(productType) {
                        HStack(alignment: .top, spacing: Constants.margin) {
                            Image(uiImage: productType.actionSheetImage.withRenderingMode(.alwaysTemplate))
                                .resizable()
                                .frame(width: Constants.productTypeIconSize, height: Constants.productTypeIconSize)
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
                }
                if category != supportedProductCategories.last {
                    Divider()
                        .padding(.vertical, Constants.categoryVerticalSpacing)
                }
            }
        }
    }
}

private extension ManualProductTypeOptions {
    enum Constants {
        static let verticalSpacing: CGFloat = 4
        static let horizontalSpacing: CGFloat = 16
        static let categoryVerticalSpacing: CGFloat = 8
        static let productBottomSpacing: CGFloat = 16
        static let productIconTopSpacing: CGFloat = 4
        static let margin: CGFloat = 16
        static let productTypeIconSize: CGFloat = 24
    }
}

#Preview {
    ManualProductTypeOptions(
        supportedProductTypes: [
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
