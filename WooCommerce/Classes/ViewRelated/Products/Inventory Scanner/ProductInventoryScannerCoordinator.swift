import UIKit

final class ProductInventoryScannerCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let siteID: Int64
    private var rootViewController: ProductInventoryScannerViewController?

    init(navigationController: UINavigationController, siteID: Int64) {
        self.navigationController = navigationController
        self.siteID = siteID
    }

    @MainActor
    func start() {
        let viewController = ProductInventoryScannerViewController(siteID: siteID)
        self.rootViewController = viewController
        viewController.showInventorySettings = { [weak self] product in
            await self?.showInventorySettings(for: product)
        }
        viewController.showProductSelector = { [weak self] sku, viewModel in
            self?.showProductSelector(for: sku, viewModel: viewModel)
        }
        viewController.confirmAddingSKUToProductWithStockManagementEnabled = { [weak self] product in
            await self?.confirmAddingSKUToProductWithStockManagementEnabled(product)
        }
        viewController.showInProgressUIAddingSKUToProduct = { [weak self] task in
            self?.showInProgressUIAddingSKUToProduct(task: task)
        }
        viewController.onSave = { [weak self] task in
            self?.save(task: task)
        }
        // Since the inventory scanner UI could hold local changes for products, disables the bottom bar (tab bar) to simplify app states.
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}

private extension ProductInventoryScannerCoordinator {
    @MainActor
    func showInventorySettings(for product: ProductFormDataModel) async -> ProductInventoryEditableData? {
        // Since the user can navigate back from inventory settings using the navigation bar back button or swiping back
        // without a consistent callback, `withUnsafeContinuation` is used here.
        await withUnsafeContinuation { continuation in
            let inventorySettingsViewController = ProductInventorySettingsViewController(product: product) { data in
                continuation.resume(returning: data)
            }
            navigationController.pushViewController(inventorySettingsViewController, animated: true)
        }
    }

    @MainActor
    func showProductSelector(for sku: String, viewModel: ProductSelectorViewModel) {
        let productSelector = ProductSelectorHostingController(configuration: .inventoryScanner, viewModel: viewModel)
        navigationController.pushViewController(productSelector, animated: true)
    }

    /// - Returns: The product for the SKU if the user chooses to enable stock management and confirm.
    @MainActor
    func confirmAddingSKUToProductWithStockManagementEnabled(_ product: ProductFormDataModel) async -> ProductFormDataModel? {
        if product.manageStock == false {
            if await presentAlertToEnableProductManageStock() == false {
                return nil
            }
        }
        return await presentAlertToConfirmAddingSKUToProduct() ? product: nil
    }

    /// - Returns: Whether the user chooses to enable product management.
    @MainActor
    func presentAlertToEnableProductManageStock() async -> Bool {
        await withCheckedContinuation { continuation in
            let alert = UIAlertController(title: Localization.EnableStockManagementAlert.title,
                                          message: Localization.EnableStockManagementAlert.message,
                                          preferredStyle: .alert)
            alert.view.tintColor = .text

            let enableAction = UIAlertAction(title: Localization.EnableStockManagementAlert.enableAction, style: .default) { _ in
                continuation.resume(returning: true)
            }
            alert.addAction(enableAction)
            alert.preferredAction = enableAction

            alert.addCancelActionWithTitle(Localization.EnableStockManagementAlert.cancelAction) { _ in
                continuation.resume(returning: false)
            }
            navigationController.present(alert, animated: true)
        }
    }

    /// - Returns: Whether the user chooses to confirm adding the scanned SKU to a product.
    @MainActor
    func presentAlertToConfirmAddingSKUToProduct() async -> Bool {
        await withCheckedContinuation { continuation in
            let alert = UIAlertController(title: Localization.AddSKUToProductAlert.title, message: nil, preferredStyle: .alert)
            alert.view.tintColor = .text

            let enableAction = UIAlertAction(title: Localization.AddSKUToProductAlert.saveAction, style: .default) { _ in
                continuation.resume(returning: true)
            }
            alert.addAction(enableAction)
            alert.preferredAction = enableAction

            alert.addCancelActionWithTitle(Localization.AddSKUToProductAlert.cancelAction) { _ in
                continuation.resume(returning: false)
            }
            navigationController.present(alert, animated: true)
        }
    }

    func showInProgressUIAddingSKUToProduct(task: @escaping () async throws -> Void) {
        presentInProgressUI(title: Localization.addSKUToProductInProgressTitle,
                            message: Localization.addSKUToProductInProgressMessage)
        Task { @MainActor [weak self] in
            guard let self else { return }
            // TODO: 2407 - error handling
            try await task()
            self.navigationController.dismiss(animated: true) { [weak self] in
                guard let self, let rootViewController = self.rootViewController else {
                    return
                }
                self.navigationController.popToViewController(rootViewController, animated: true)
            }
        }
    }

    func save(task: @escaping () async throws -> Void) {
        presentInProgressUI(title: Localization.productInventoryUpdateInProgressTitle,
                            message: Localization.productInventoryUpdateInProgressMessage)
        Task { @MainActor [weak self] in
            guard let self else { return }
            // TODO: 2407 - error handling
            try await task()
            self.navigationController.dismiss(animated: true) { [weak self] in
                self?.navigationController.popViewController(animated: true)
            }
        }
    }
}

private extension ProductInventoryScannerCoordinator {
    func presentInProgressUI(title: String, message: String) {
        let viewProperties = InProgressViewProperties(title: title,
                                                      message: message)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext
        navigationController.present(inProgressViewController, animated: true)
    }
}

private extension ProductInventoryScannerCoordinator {
    enum Localization {
        enum EnableStockManagementAlert {
            static let title = NSLocalizedString(
                "Stock management isn't activated",
                comment: "Title of the alert for turning on stock management for a product to be linked to a scanned SKU in inventory scanner."
            )
            static let message = NSLocalizedString(
                "You need to turn on stock management for this product to update inventory",
                comment: "Message of the alert for turning on stock management for a product to be linked to a scanned SKU in inventory scanner."
            )
            static let enableAction = NSLocalizedString(
                "Turn on",
                comment: "Title of the alert action to turn on stock management for a product to be linked to a scanned SKU in inventory scanner."
            )
            static let cancelAction = NSLocalizedString(
                "Cancel",
                comment: "Title of the alert action to cancel turning on stock management for a product to be linked to a scanned SKU in inventory scanner."
            )
        }
        enum AddSKUToProductAlert {
            static let title = NSLocalizedString(
                "Save barcode to this product?",
                comment: "Title of the alert for confirming saving a scanned barcode to a selected product in inventory scanner."
            )
            static let saveAction = NSLocalizedString(
                "Save",
                comment: "Title of the alert action to confirm saving a scanned barcode to a selected product in inventory scanner."
            )
            static let cancelAction = NSLocalizedString(
                "Cancel",
                comment: "Title of the alert action to cancel saving a scanned barcode to a selected product in inventory scanner."
            )
        }
        static let productInventoryUpdateInProgressTitle = NSLocalizedString(
            "Updating inventory",
            comment: "Title of the in-progress UI while updating the product inventory settings remotely in inventory scanner."
        )
        static let productInventoryUpdateInProgressMessage = NSLocalizedString(
            "Please wait while we update inventory for your products",
            comment: "Message of the in-progress UI while updating the product inventory settings remotely in inventory scanner."
        )
        static let addSKUToProductInProgressTitle = NSLocalizedString(
            "Adding SKU to product",
            comment: "Title of the in-progress UI while adding the scanned barcode to a product in inventory scanner."
        )
        static let addSKUToProductInProgressMessage = NSLocalizedString(
            "Please wait while we add the scanned SKU to your product.",
            comment: "Message of the in-progress UI while adding the scanned barcode to a product in inventory scanner."
        )
    }
}

private extension ProductSelectorView.Configuration {
    static let inventoryScanner: Self =
        .init(showsFilters: true,
              multipleSelectionsEnabled: false,
              prefersLargeTitle: false,
              title: Localization.title,
              cancelButtonTitle: nil,
              productRowAccessibilityHint: Localization.productRowAccessibilityHint,
              variableProductRowAccessibilityHint: Localization.variableProductRowAccessibilityHint)

    enum Localization {
        static let title = NSLocalizedString("Products", comment: "Title for the screen to select a product for a scanned SKU.")
        static let productRowAccessibilityHint = NSLocalizedString(
            "Selection of a product for a scanned SKU in inventory scanner.",
            comment: "Accessibility hint for selecting a product for a scanned SKU in inventory scanner."
        )
        static let variableProductRowAccessibilityHint = NSLocalizedString(
            "Opens list of product variations.",
            comment: "Accessibility hint for selecting a variable product in the Select Products screen"
        )
    }
}
