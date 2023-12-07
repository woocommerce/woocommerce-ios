import SwiftUI

final class ProductWithQuantityStepperViewModel: ObservableObject, Identifiable {
    let stepperViewModel: ProductStepperViewModel
    let rowViewModel: ProductRowViewModel

    /// Whether the product quantity can be changed.
    /// Controls whether the stepper is rendered.
    ///
    @Published private(set) var canChangeQuantity: Bool

    // TODO: 11357 - move to `CollapsibleProductCard`'s own view model
    /// Whether the product row is read-only. Defaults to `false`.
    ///
    /// Used to remove product editing controls for read-only order items (e.g. child items of a product bundle).
    let isReadOnly: Bool

    // TODO: 11357 - move to `CollapsibleProductCard`'s own view model
    /// Child product rows, if the product is the parent of child order items
    @Published private(set) var childProductRows: [ProductWithQuantityStepperViewModel]

    init(stepperViewModel: ProductStepperViewModel,
         rowViewModel: ProductRowViewModel,
         canChangeQuantity: Bool,
         isReadOnly: Bool = false,
         childProductRows: [ProductWithQuantityStepperViewModel] = []) {
        self.stepperViewModel = stepperViewModel
        self.rowViewModel = rowViewModel
        self.canChangeQuantity = canChangeQuantity
        self.isReadOnly = isReadOnly
        self.childProductRows = childProductRows

        observeQuantityFromStepperViewModel()
    }
}

private extension ProductWithQuantityStepperViewModel {
    func observeQuantityFromStepperViewModel() {
        stepperViewModel.$quantity
            .assign(to: &rowViewModel.$quantity)
    }
}

struct ProductWithQuantityStepperView: View {
    @ObservedObject var viewModel: ProductWithQuantityStepperViewModel

    var body: some View {
        VStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                ProductRow(viewModel: viewModel.rowViewModel)
                ProductStepper(viewModel: viewModel.stepperViewModel)
                    .renderedIf(viewModel.canChangeQuantity)
            }
        }
    }
}

struct ProductWithQuantityStepperView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        // TODO-jc: fix preview
//        ProductWithQuantityStepperView(viewModel: <#ProductWithQuantityStepperViewModel#>)
    }
}
