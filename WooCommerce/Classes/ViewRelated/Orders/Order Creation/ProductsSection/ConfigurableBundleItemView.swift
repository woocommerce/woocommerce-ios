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
            HStack(spacing: Layout.defaultPadding) {
                Button {
                    viewModel.isOptionalAndSelected.toggle()
                } label: {
                    Image(uiImage: viewModel.isOptionalAndSelected || !viewModel.isOptional ?
                        .checkCircleImage.withRenderingMode(.alwaysTemplate):
                            .checkEmptyCircleImage)
                    .frame(width: Layout.checkmarkDimension, height: Layout.checkmarkDimension)
                    .foregroundColor(.init(viewModel.isOptional ? .accent: .placeholderImage))
                }
                .disabled(!viewModel.isOptional)

                if viewModel.canChangeQuantity {
                    ProductWithQuantityStepperView(viewModel: viewModel.productWithStepperViewModel)
                } else {
                    ProductRow(viewModel: viewModel.productWithStepperViewModel.rowViewModel)
                }
            }

            HStack(spacing: 0) {
                // Indentation from the checkmark image.
                Spacer()
                    .frame(width: Layout.checkmarkDimension + Layout.defaultPadding)

                VStack(alignment: .leading, spacing: Layout.defaultPadding) {
                    Divider()
                        .dividerStyle()

                    if let selectedVariation = viewModel.selectedVariation {
                        ForEach(selectedVariation.attributes, id: \.name) { attribute in
                            HStack {
                                Text(attribute.name)
                                    .bold()
                                    .foregroundColor(Color(.text))
                                    .subheadlineStyle()
                                Text(attribute.option)
                                    .foregroundColor(Color(.text))
                                    .subheadlineStyle()
                            }
                        }

                        ForEach(viewModel.selectableVariationAttributeViewModels) { viewModel in
                            ConfigurableVariableBundleAttributePicker(viewModel: viewModel)
                        }
                    }

                    Button {
                        viewModel.createVariationSelectorViewModel()
                        showsVariationSelector = true
                    } label: {
                        HStack {
                            Text(viewModel.selectedVariation == nil ?
                                 Localization.selectVariation: Localization.updateVariation)
                            .bold()
                            .foregroundColor(Color(.accent))
                            .subheadlineStyle()

                            Spacer()

                            DisclosureIndicator()
                        }
                    }
                }
            }
            .renderedIf(viewModel.isVariable && viewModel.isIncludedInBundle && viewModel.quantity > 0)

            if let variationSelectorViewModel = viewModel.variationSelectorViewModel {
                LazyNavigationLink(destination: ProductVariationSelectorView(
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
        static let checkmarkDimension: CGFloat = 24
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
