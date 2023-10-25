import SwiftUI

/// Allows the user to configure a bundle item of a bundle product associated with an order item.
struct ConfigurableBundleItemView: View {
    @ObservedObject private var viewModel: ConfigurableBundleItemViewModel
    @State private var showsVariationSelector: Bool = false

    init(viewModel: ConfigurableBundleItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    viewModel.isOptionalAndSelected.toggle()
                } label: {
                    Image(uiImage: viewModel.isOptionalAndSelected ?
                        .checkCircleImage.withRenderingMode(.alwaysTemplate):
                            .checkEmptyCircleImage)
                        .foregroundColor(.init(.brand))
                }
                    .renderedIf(viewModel.isOptional)

                ProductRow(viewModel: viewModel.productRowViewModel)
            }

            Button {
                viewModel.createVariationSelectorViewModel()
                showsVariationSelector = true
            } label: {
                Text(Localization.selectVariation)
            }
            .renderedIf(viewModel.isVariable)

            if let selectedVariation = viewModel.selectedVariation {
                Text(selectedVariation.attributes.map { "\($0.name): \($0.option)" }.joined(separator: ", "))
            }

            if let variationSelectorViewModel = viewModel.variationSelectorViewModel {
                LazyNavigationLink(destination: ProductVariationSelector(
                    isPresented: $showsVariationSelector,
                    viewModel: variationSelectorViewModel,
                    onMultipleSelections: { _ in }),
                    isActive: $showsVariationSelector) {
                    EmptyView()
                }
            }
        }
        .padding()
    }
}

private extension ConfigurableBundleItemView {
    enum Localization {
        static let add = NSLocalizedString(
            "configureBundleItem.add",
            value: "Add",
            comment: "Action to toggle whether a bundle item is included when it is optional."
        )
        static let selectVariation = NSLocalizedString(
            "configureBundleItem.selectVariation",
            value: "Select variation",
            comment: "Action to select a variation for a bundle item when it is variable."
        )
    }
}

#if canImport(SwiftUI) && DEBUG

struct ConfigurableBundleItemView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurableBundleItemView(viewModel: .init(bundleItem: .swiftUIPreviewSample(),
                                                    product: .swiftUIPreviewSample(),
                                                    variableProductSettings: nil,
                                                    existingOrderItem: nil))
    }
}

#endif