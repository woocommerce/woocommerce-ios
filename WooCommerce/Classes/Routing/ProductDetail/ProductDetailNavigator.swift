import UIKit
import Yosemite

/// Decides between **native** and **admin web** product detail flows and builds the destination VC.
final class ProductDetailNavigator {
    /// Describes how the **native** destination should be presented.
    enum Presentation {
        case push
        case contained(in: () -> UIViewController?)

        var asProductFormPresentationStyle: ProductFormPresentationStyle {
            switch self {
            case .contained(let inVC):
                    .contained(containerViewController: inVC)
            case .push:
                    .navigationStack
            }
        }
    }

    static var shared = ProductDetailNavigator()

    private let ciabChecker: CIABEligibilityCheckerProtocol
    private let coordinatorFactory: ProductDetailCoordinatorFactoryProtocol
    private let stores: StoresManager

    init(ciabChecker: CIABEligibilityCheckerProtocol = CIABEligibilityChecker(),
         coordinatorFactory: ProductDetailCoordinatorFactoryProtocol = ProductDetailCoordinatorFactory.default,
         stores: StoresManager = ServiceLocator.stores,
    ) {
        self.ciabChecker = ciabChecker
        self.coordinatorFactory = coordinatorFactory
        self.stores = stores
    }

    /// Builds the destination `UIViewController` for the given product.
    /// - Parameters:
    ///   - product: The product to display.
    ///   - presentationStyle: How to present **native** detail (ignored for web).
    ///   - isReadOnly: Whether the native screen should be read-only.
    ///   - onDelete: Optional callback invoked after a successful product delete.
    /// - Returns: A ready-to-present view controller (native or web).
    func makeDestination(product: Product,
                         presentationStyle: Presentation = .push,
                         isReadOnly: Bool,
                         onDismissWeb: (() -> Void)? = nil,
                         onDelete: (() -> Void)? = nil) -> UIViewController {

        let viewController: UIViewController
        if shouldOpenInWeb(product: product) {
            let coordinator = coordinatorFactory.webCoordinator(site: stores.sessionManager.defaultSite)
            viewController = coordinator.viewController(product: product) {
                onDismissWeb?()
            }
        } else {
            let coordinator = coordinatorFactory.nativeCoordinator()
            viewController = coordinator.viewController(product: product,
                                                        presentationStyle: presentationStyle,
                                                        isReadOnly: isReadOnly,
                                                        onDelete: onDelete)
        }

        return viewController
    }

    private func shouldOpenInWeb(product: Product) -> Bool {
        let isLegacyBookableType = product.productType == .legacyBooking
        let isNewBookableType = ciabChecker.isCurrentSiteCIAB && product.productType == .booking
        return isLegacyBookableType || isNewBookableType
    }
}
