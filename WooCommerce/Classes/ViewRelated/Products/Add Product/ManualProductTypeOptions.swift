import SwiftUI

/// View to show the manual product type creation options.
///
struct ManualProductTypeOptions: View {
    private let productTypes: [BottomSheetProductType]
    private let onOptionSelected: (BottomSheetProductType) -> Void

    init(productTypes: [BottomSheetProductType],
         onOptionSelected: @escaping (BottomSheetProductType) -> Void) {
        self.productTypes = productTypes
        self.onOptionSelected = onOptionSelected
    }

    var body: some View {
        ForEach(productTypes) { productType in
            HStack(alignment: .top, spacing: Constants.margin) {
                Image(uiImage: productType.actionSheetImage.withRenderingMode(.alwaysTemplate))
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    Text(productType.actionSheetTitle)
                        .bodyStyle()
                    Text(productType.actionSheetDescription)
                        .subheadlineStyle()
                }
                Spacer()
            }
            .onTapGesture {
                onOptionSelected(productType)
            }
        }
    }
}

private extension ManualProductTypeOptions {
    enum Constants {
        static let verticalSpacing: CGFloat = 4
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
