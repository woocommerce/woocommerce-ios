import SwiftUI

final class ProductWithQuantityStepperViewModel: ObservableObject {
    let stepperViewModel: ProductStepperViewModel
    let rowViewModel: ProductRowViewModel

    /// Whether the product quantity can be changed.
    /// Controls whether the stepper is rendered.
    ///
    @Published private(set) var canChangeQuantity: Bool

    init(stepperViewModel: ProductStepperViewModel, rowViewModel: ProductRowViewModel, canChangeQuantity: Bool) {
        self.stepperViewModel = stepperViewModel
        self.rowViewModel = rowViewModel
        self.canChangeQuantity = canChangeQuantity

        observeQuantityFromStepperViewModel()
    }

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
