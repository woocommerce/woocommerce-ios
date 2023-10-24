import SwiftUI

/// Allows the user to configure a bundle product associated with an order item.
struct ConfigurableBundleProductView: View {
    @ObservedObject private var viewModel: ConfigurableBundleProductViewModel
    @Environment(\.presentationMode) private var presentation
    @Environment(\.presentationMode) private var presentationMode

    init(viewModel: ConfigurableBundleProductViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Layout.noSpacing) {
                    ForEach(viewModel.bundleItemViewModels) { bundleItemViewModel in
                        ConfigurableBundleItemView(viewModel: bundleItemViewModel)
                    }
                    .background(Color(.listForeground(modal: false)))
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        presentation.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        viewModel.configure()
                        presentation.wrappedValue.dismiss()
                    }
                    .disabled(!viewModel.isConfigureEnabled)
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
    }

    enum Localization {
        static let title = NSLocalizedString("Configure", comment: "Title for the Product screen during order creation")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Product screen")
        static let done = NSLocalizedString("Done", comment: "Text for the done button in the Product screen")
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
        return ConfigurableBundleProductView(viewModel: .init(product: product, onConfigure: { _ in }))
    }
}

#endif
