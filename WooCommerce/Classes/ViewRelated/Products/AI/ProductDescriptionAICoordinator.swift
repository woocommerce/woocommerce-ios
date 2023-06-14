import UIKit
import struct Yosemite.Site

/// Coordinates navigation for product description AI.
final class ProductDescriptionAICoordinator: Coordinator {
    typealias Source = WooAnalyticsEvent.ProductFormAI.ProductDescriptionAISource

    let navigationController: UINavigationController

    private let product: ProductFormDataModel
    private let source: Source
    private let analytics: Analytics
    private let onApply: (ProductDescriptionGenerationOutput) -> Void

    private var productDescriptionGenerationBottomSheetPresenter: BottomSheetPresenter?

    init(product: ProductFormDataModel,
         navigationController: UINavigationController,
         source: Source,
         analytics: Analytics,
         onApply: @escaping (ProductDescriptionGenerationOutput) -> Void) {
        self.product = product
        self.navigationController = navigationController
        self.source = source
        self.analytics = analytics
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
        }))

        navigationController.view.endEditing(true)
        productDescriptionGenerationBottomSheetPresenter?.present(controller, from: navigationController)
        analytics.track(event: .ProductFormAI.productDescriptionAIButtonTapped(source: source))
    }

    func dismissDescriptionGenerationBottomSheetIfNeeded() {
        productDescriptionGenerationBottomSheetPresenter?.dismiss(onDismiss: {})
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
