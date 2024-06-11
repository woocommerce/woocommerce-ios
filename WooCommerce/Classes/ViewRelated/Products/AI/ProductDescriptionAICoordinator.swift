import UIKit
import struct Yosemite.Site
import protocol WooFoundation.Analytics

/// Coordinates navigation for product description AI.
final class ProductDescriptionAICoordinator: Coordinator {
    typealias Source = WooAnalyticsEvent.ProductFormAI.ProductDescriptionAISource

    let navigationController: UINavigationController

    private let product: ProductFormDataModel
    private let source: Source
    private let analytics: Analytics
    private let userDefaults: UserDefaults
    private let onApply: (ProductDescriptionGenerationOutput) -> Void

    private var productDescriptionGenerationBottomSheetPresenter: BottomSheetPresenter?
    private var celebrationViewBottomSheetPresenter: BottomSheetPresenter?

    init(product: ProductFormDataModel,
         navigationController: UINavigationController,
         source: Source,
         analytics: Analytics,
         userDefaults: UserDefaults = .standard,
         onApply: @escaping (ProductDescriptionGenerationOutput) -> Void) {
        self.product = product
        self.navigationController = navigationController
        self.source = source
        self.analytics = analytics
        self.userDefaults = userDefaults
        self.onApply = onApply
    }

    func start() {
        presentAIBottomSheet()
    }
}

// MARK: Navigation
private extension ProductDescriptionAICoordinator {
    func presentAIBottomSheet() {
        productDescriptionGenerationBottomSheetPresenter = buildBottomSheetPresenter()

        let controller = ProductDescriptionGenerationHostingController(viewModel:
                .init(siteID: product.siteID,
                      name: product.name,
                      description: product.description ?? "",
                      onApply: { [weak self] output in
            guard let self else { return }
            self.onApply(output)
            self.dismissDescriptionGenerationBottomSheetIfNeeded()
            if !self.userDefaults.usedProductDescriptionAI {
                self.userDefaults[.usedProductDescriptionAI] = true
                self.showProductDescriptionAICelebrationView()
            }
        }))

        navigationController.view.endEditing(true)
        productDescriptionGenerationBottomSheetPresenter?.present(controller, from: navigationController)
        analytics.track(event: .ProductFormAI.productDescriptionAIButtonTapped(source: source))
    }

    func dismissDescriptionGenerationBottomSheetIfNeeded() {
        productDescriptionGenerationBottomSheetPresenter?.dismiss(onDismiss: {})
    }

    func showProductDescriptionAICelebrationView() {
        celebrationViewBottomSheetPresenter = buildBottomSheetPresenter()
        let controller = ProductDescriptionGenerationCelebrationHostingController(viewModel: .init(onTappingGotIt: { [weak self] in
            self?.celebrationViewBottomSheetPresenter?.dismiss()
            self?.celebrationViewBottomSheetPresenter = nil
        }))
        celebrationViewBottomSheetPresenter?.present(controller, from: navigationController)
    }
}

// MARK: Bottom sheet helpers
//
private extension ProductDescriptionAICoordinator {
    func buildBottomSheetPresenter() -> BottomSheetPresenter {
        BottomSheetPresenter(configure: { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .none
            sheet.prefersGrabberVisible = true
            sheet.detents = [.medium(), .large()]
        })
    }
}

// MARK: UserDefaults helpers
//
private extension UserDefaults {
    @objc dynamic var usedProductDescriptionAI: Bool {
        bool(forKey: Key.usedProductDescriptionAI.rawValue)
    }
}
