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
                    Image(uiImage: viewModel.isOptionalAndSelected || !viewModel.isOptional ?
                        .checkCircleImage.withRenderingMode(.alwaysTemplate):
                            .checkEmptyCircleImage)
                    .foregroundColor(.init(viewModel.isOptional ? .accent: .placeholderImage))
                }
                .disabled(!viewModel.isOptional)

                ProductRow(viewModel: viewModel.productRowViewModel)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .errorStyle()
            }

            Button {
                viewModel.createVariationSelectorViewModel()
                showsVariationSelector = true
            } label: {
                Text(viewModel.selectedVariation == nil ?
                     Localization.selectVariation: Localization.updateVariation)
            }
            .renderedIf(viewModel.isVariable && viewModel.isIncludedInBundle && viewModel.quantity > 0)

            if let selectedVariation = viewModel.selectedVariation {
                Spacer()
                    .frame(height: Layout.defaultPadding)

                ForEach(selectedVariation.attributes, id: \.name) { attribute in
                    HStack {
                        Text(attribute.name)
                            .bold()
                        Text(attribute.option)
                    }
                }

                ForEach(viewModel.selectableVariationAttributeViewModels) { viewModel in
                    ConfigurableVariableBundleAttributePicker(viewModel: viewModel)
                }
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
    enum Layout {
        static let defaultPadding: CGFloat = 16
    }

    enum Localization {
        static let add = NSLocalizedString(
            "configureBundleItem.add",
            value: "Add",
            comment: "Action to toggle whether a bundle item is included when it is optional."
        )
        static let selectVariation = NSLocalizedString(
            "configureBundleItem.chooseVariation",
            value: "Choose variation",
            comment: "Action to select a variation for a bundle item when it is variable."
        )
        static let updateVariation = NSLocalizedString(
            "configureBundleItem.updateVariation",
            value: "Update variation",
            comment: "Action to update a variation for a bundle item when it is variable."
        )
    }
}

#if canImport(SwiftUI) && DEBUG

struct ConfigurableBundleItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ConfigurableBundleItemView(viewModel: .init(bundleItem: .swiftUIPreviewSample().copy(isOptional: false),
                                                        product: .swiftUIPreviewSample(),
                                                        variableProductSettings: nil,
                                                        existingParentOrderItem: nil,
                                                        existingOrderItem: nil))
            ConfigurableBundleItemView(viewModel: .init(bundleItem: .swiftUIPreviewSample().copy(isOptional: true),
                                                        product: .swiftUIPreviewSample(),
                                                        variableProductSettings: nil,
                                                        existingParentOrderItem: nil,
                                                        existingOrderItem: nil))
        }
    }
}

#endif
