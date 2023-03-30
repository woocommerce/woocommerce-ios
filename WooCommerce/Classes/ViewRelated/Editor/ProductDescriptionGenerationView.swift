import SwiftUI

/// Hosting controller for `ProductDescriptionGenerationView`.
///
final class ProductDescriptionGenerationHostingController: UIHostingController<ProductDescriptionGenerationView> {
    init(viewModel: ProductDescriptionGenerationViewModel) {
        super.init(rootView: ProductDescriptionGenerationView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

struct ProductDescriptionGenerationView: View {
    @ObservedObject private var viewModel: ProductDescriptionGenerationViewModel

    init(viewModel: ProductDescriptionGenerationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack {
                Text(viewModel.name)
                    .headlineStyle()
                TextField("", text: $viewModel.productDescription)
                    .bodyStyle()
                Button("🪄") {
                    Task { @MainActor in
                        await viewModel.generateDescription()
                    }
                }.buttonStyle(PrimaryButtonStyle())
            }.padding()
        }
    }
}

#if DEBUG

struct ProductDescriptionGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
//        ProductDescriptionGenerationView(.init(product: TODO-JC))
    }
}

#endif
