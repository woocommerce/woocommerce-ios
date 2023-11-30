import SwiftUI

/// Allows the user to configure a bundle product associated with an order item.
struct ConfigurableBundleProductView: View {
    @ObservedObject private var viewModel: ConfigurableBundleProductViewModel
    @Environment(\.presentationMode) private var presentation
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    init(viewModel: ConfigurableBundleProductViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ScrollView {
                    VStack(spacing: Layout.noSpacing) {
                        if let loadProductsErrorMessage = viewModel.loadProductsErrorMessage {
                            Group {
                                Text(loadProductsErrorMessage)
                                    .errorStyle()
                                Button(Localization.retry) {
                                    viewModel.retry()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            .padding()
                        }

                        ForEach(viewModel.bundleItemViewModels) { bundleItemViewModel in
                            ConfigurableBundleItemView(viewModel: bundleItemViewModel)
                            Divider()
                                .dividerStyle()
                                .padding(.leading, Layout.defaultPadding)
                        }
                        .renderedIf(viewModel.bundleItemViewModels.isNotEmpty)

                        ForEach(viewModel.placeholderItemViewModels) { bundleItemViewModel in
                            ConfigurableBundleItemView(viewModel: bundleItemViewModel)
                            Divider()
                                .dividerStyle()
                                .padding(.leading, Layout.defaultPadding)
                        }
                        .redacted(reason: .placeholder)
                        .shimmering()
                        .renderedIf(viewModel.bundleItemViewModels.isEmpty && viewModel.loadProductsErrorMessage == nil)
                    }
                }

                ConfigurableBundleNoticeView(validationState: viewModel.validationState)
                    .padding(.horizontal, insets: .init(top: 0, leading: Layout.defaultPadding, bottom: 0, trailing: Layout.defaultPadding))
                    .renderedIf(viewModel.showsValidationNotice)

                Button(Localization.save) {
                    viewModel.configure()
                    presentation.wrappedValue.dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.isConfigureEnabled)
                .padding(Layout.defaultPadding)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .background(Color(.listForeground(modal: false)))
            .ignoresSafeArea(.container, edges: [.horizontal])
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
        }
        .wooNavigationBarStyle()
    }
}

// MARK: Constants
private extension ConfigurableBundleProductView {
    enum Layout {
        static let noSpacing: CGFloat = 0.0
        static let defaultPadding: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString(
            "configureBundleProduct.title",
            value: "Configure", comment: "Title for the bundle product configuration screen in the order form."
        )
        static let close = NSLocalizedString(
            "configureBundleProduct.close",
            value: "Close",
            comment: "Text for the close button in the bundle product configuration screen in the order form."
        )
        static let save = NSLocalizedString(
            "configureBundleProduct.save",
            value: "Save Configuration",
            comment: "Text for the save button in the bundle product configuration screen in the order form."
        )
        static let retry = NSLocalizedString(
            "configureBundleProduct.retry",
            value: "Retry",
            comment: "Text for the retry button to reload bundled products in the bundle product configuration screen in the order form."
        )
    }
}

#if canImport(SwiftUI) && DEBUG

import Yosemite

struct ConfigurableBundleProductView_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product.swiftUIPreviewSample()
            .copy(bundledItems: [
                .swiftUIPreviewSample()
            ])
        return ConfigurableBundleProductView(viewModel: .init(product: product, childItems: [], onConfigure: { _ in }))
    }
}

#endif
