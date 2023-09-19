import Foundation

enum AddProductWithAIStep: Int, CaseIterable {
    case productName = 1
    case aboutProduct
    case preview

    /// Progress to display
    var progress: Double {
        let incrementBy = 1.0 / Double(Self.allCases.count)
        return Double(self.rawValue) * incrementBy
    }

    var previousStep: AddProductWithAIStep? {
        .init(rawValue: self.rawValue - 1)
    }
}

/// View model for `AddProductWithAIContainerView`.
final class AddProductWithAIContainerViewModel: ObservableObject {

    let siteID: Int64
    let source: AddProductCoordinator.Source

    var presentPackageFlow: ((_ productName: String?, @escaping (AddProductFromImageData?) -> Void) -> Void)?

    private let analytics: Analytics
    private let onCancel: () -> Void
    private let completionHandler: () -> Void

    @Published private(set) var currentStep: AddProductWithAIStep = .productName

    init(siteID: Int64,
         source: AddProductCoordinator.Source,
         analytics: Analytics = ServiceLocator.analytics,
         onCancel: @escaping () -> Void,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.source = source
        self.analytics = analytics
        self.onCancel = onCancel
        self.completionHandler = onCompletion
    }

    func onAppear() {
        //
    }

    func onContinueWithProductName(name: String) {
        // TODO: Continue to About your product screen
    }

    func onUsePackagePhoto(_ name: String?) {
        presentPackageFlow?(name) { data in
            // TODO: Present preview
        }
    }

    func backtrackOrDismiss() {
        if let previousStep = currentStep.previousStep {
            currentStep = previousStep
        } else {
            onCancel()
        }
    }
}

private extension AddProductWithAIContainerViewModel {
    func handleCompletion() {
        completionHandler()
    }
}
