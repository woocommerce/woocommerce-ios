import Foundation
import Yosemite
import protocol WooFoundation.Analytics
import Experiments

enum AddProductWithAIStep: Int, CaseIterable {
    case productName = 1
    case aboutProduct
    case preview

    var previousStep: AddProductWithAIStep? {
        .init(rawValue: self.rawValue - 1)
    }
}

/// View model for `AddProductWithAIContainerView`.
final class AddProductWithAIContainerViewModel: ObservableObject {

    let siteID: Int64
    let source: AddProductCoordinator.Source

    var canBeDismissed: Bool {
        currentStep == .productName && startingInfoViewModel.productFeatures == nil
    }

    private let analytics: Analytics
    private let onCancel: () -> Void
    private let completionHandler: (Product) -> Void

    private(set) var productName: String = ""
    private(set) var productFeatures: String = ""
    private(set) var productDescription: String?
    private var isFirstAttemptGeneratingDetails: Bool

    private(set) lazy var startingInfoViewModel: ProductCreationAIStartingInfoViewModel = {
        ProductCreationAIStartingInfoViewModel(siteID: siteID)
    }()

    @Published private(set) var currentStep: AddProductWithAIStep = .productName

    init(siteID: Int64,
         source: AddProductCoordinator.Source,
         analytics: Analytics = ServiceLocator.analytics,
         onCancel: @escaping () -> Void,
         onCompletion: @escaping (Product) -> Void) {
        self.siteID = siteID
        self.source = source
        self.analytics = analytics
        self.onCancel = onCancel
        self.completionHandler = onCompletion
        isFirstAttemptGeneratingDetails = true
    }

    func onAppear() {
        //
    }

    func onContinueWithProductName(name: String) {
        productName = name
        currentStep = .aboutProduct
    }

    func onProductFeaturesAdded(features: String) {
        analytics.track(event: .ProductCreationAI.generateDetailsTapped(isFirstAttempt: isFirstAttemptGeneratingDetails,
                                                                        features: features))
        productFeatures = features
        currentStep = .preview
        isFirstAttemptGeneratingDetails = false
    }

    func didCreateProduct(_ product: Product) {
        completionHandler(product)
    }

    func backtrackOrDismiss() {
        if let previousStep = currentStep.previousStep {
            currentStep = previousStep
        } else {
            onCancel()
        }
    }
}
