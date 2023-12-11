import SwiftUI

/// View model for `ProductWithQuantityStepperView`.
final class ProductWithQuantityStepperViewModel: ObservableObject, Identifiable {
    let stepperViewModel: ProductStepperViewModel
    let rowViewModel: ProductRowViewModel

    init(stepperViewModel: ProductStepperViewModel,
         rowViewModel: ProductRowViewModel) {
        self.stepperViewModel = stepperViewModel
        self.rowViewModel = rowViewModel

        observeQuantityFromStepperViewModel()
    }
}

private extension ProductWithQuantityStepperViewModel {
    func observeQuantityFromStepperViewModel() {
        stepperViewModel.$quantity
            .assign(to: &rowViewModel.$quantity)
    }
}
