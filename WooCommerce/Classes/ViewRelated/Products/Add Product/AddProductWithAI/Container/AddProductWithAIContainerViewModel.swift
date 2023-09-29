import Foundation
import Yosemite

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

    var canBeDismissed: Bool {
        currentStep == .productName && addProductNameViewModel.productName == nil
    }

    private let analytics: Analytics
    private let onCancel: () -> Void
    private let completionHandler: (Product) -> Void

    private(set) var productName: String = ""
    private(set) var productFeatures: String = ""
    private(set) var productDescription: String?

    private(set) lazy var addProductNameViewModel: AddProductNameWithAIViewModel = {
        .init(siteID: siteID)
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
    }

    func onAppear() {
        //
    }

    func onContinueWithProductName(name: String) {
        productName = name
        currentStep = .aboutProduct
    }

    func onProductFeaturesAdded(features: String) {
        productFeatures = features
        currentStep = .preview
    }

    func didCreateProduct(_ product: Product) {
        completionHandler(product)
    }

    func didGenerateDataFromPackage(_ data: AddProductFromImageData?) {
        guard let data else {
            return
        }
        productName = data.name
        productDescription = data.description
        productFeatures = data.description
        currentStep = .preview
    }

    func backtrackOrDismiss() {
        if let previousStep = currentStep.previousStep {
            currentStep = previousStep
        } else {
            onCancel()
        }
    }
}
