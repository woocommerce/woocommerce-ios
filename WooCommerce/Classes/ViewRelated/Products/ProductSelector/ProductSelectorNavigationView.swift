import SwiftUI

/// `ProductSelectorView` wrapped in a SwiftUI navigation view.
struct ProductSelectorNavigationView: View {
    private let configuration: ProductSelectorView.Configuration
    private let source: ProductSelectorSource
    @Binding private var isPresented: Bool
    private let viewModel: ProductSelectorViewModel

    init(configuration: ProductSelectorView.Configuration,
         source: ProductSelectorSource,
         isPresented: Binding<Bool>,
         viewModel: ProductSelectorViewModel) {
        self.configuration = configuration
        self.source = source
        self._isPresented = isPresented
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ProductSelectorView(configuration: configuration,
                                source: source,
                                isPresented: $isPresented,
                                viewModel: viewModel)
        }
        .navigationViewStyle(.stack)
        .wooNavigationBarStyle()
    }
}

struct ProductSelectorNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductSelectorViewModel(siteID: 123)
        let configuration = ProductSelectorView.Configuration(
            title: "Add Product",
            cancelButtonTitle: "Close",
            productRowAccessibilityHint: "Add product to order",
            variableProductRowAccessibilityHint: "Open variation list")
        ProductSelectorNavigationView(configuration: configuration, source: .orderForm(flow: .creation), isPresented: .constant(true), viewModel: viewModel)
    }
}
