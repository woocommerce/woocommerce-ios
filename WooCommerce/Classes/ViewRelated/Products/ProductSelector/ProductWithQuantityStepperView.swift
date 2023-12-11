import SwiftUI

/// Displays a product row with an option to change its quantity, mostly used in the order creation/editing context.
struct ProductWithQuantityStepperView: View {
    @ObservedObject var viewModel: ProductWithQuantityStepperViewModel

    var body: some View {
        VStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                ProductRow(viewModel: viewModel.rowViewModel)
                ProductStepper(viewModel: viewModel.stepperViewModel)
            }
        }
    }
}

#if canImport(SwiftUI) && DEBUG
struct ProductWithQuantityStepperView_Previews: PreviewProvider {
    static var previews: some View {
        let stepperViewModel = ProductStepperViewModel(quantity: 2,
                                                       name: "",
                                                       quantityUpdatedCallback: { _ in })
        let rowViewModel = ProductRowViewModel(product: .swiftUIPreviewSample())
        VStack {
            ProductWithQuantityStepperView(viewModel: .init(stepperViewModel: stepperViewModel, rowViewModel: rowViewModel))
            ProductWithQuantityStepperView(viewModel: .init(stepperViewModel: stepperViewModel, rowViewModel: rowViewModel))
        }
    }
}
#endif
