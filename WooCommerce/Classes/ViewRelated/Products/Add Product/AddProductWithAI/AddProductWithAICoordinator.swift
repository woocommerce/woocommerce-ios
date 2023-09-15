import UIKit
import Yosemite

/// Coordinator for the add product with AI flow.
///
final class AddProductWithAICoordinator: Coordinator {

    let navigationController: UINavigationController

    private let siteID: Int64
    private let source: AddProductCoordinator.Source

    /// Invoked when a new product is saved remotely.
    private let onProductCreated: (Product) -> Void

    init(siteID: Int64,
         source: AddProductCoordinator.Source,
         sourceNavigationController: UINavigationController,
         onProductCreated: @escaping (Product) -> Void) {
        self.siteID = siteID
        self.source = source
        self.navigationController = sourceNavigationController
        self.onProductCreated = onProductCreated
    }

    func start() {
        // TODO-10688: present form for adding product name
    }
}
