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
    private let analytics: Analytics
    private let onCancel: () -> Void
    private let completionHandler: () -> Void

    @Published private(set) var currentStep: AddProductWithAIStep = .productName

    init(siteID: Int64,
         analytics: Analytics = ServiceLocator.analytics,
         onCancel: @escaping () -> Void,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
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
        // TODO: Launch UsePackagePhoto flow
    }

    func backtrackOrDismissProfiler() {
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
