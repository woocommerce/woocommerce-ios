import UIKit
import Yosemite

/// ProductFormViewController Helpers
///
extension ProductFormViewController {

    // MARK: - Alert

    /// Product Type Change alert
    ///
    func presentProductTypeChangeAlert(for productType: ProductType, completion: @escaping (Bool) -> ()) {
        let body: String
        switch productType {
        case .variable:
            body = Localization.Alert.productVariableTypeChangeMessage
        default:
            body = Localization.Alert.productTypeChangeMessage
        }

        let alertController = UIAlertController(title: Localization.Alert.productTypeChangeTitle,
                                                message: body,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localization.Alert.productTypeChangeCancelButton,
                                   style: .cancel) { (action) in
                                       completion(false)
                                   }
        let confirm = UIAlertAction(title: Localization.Alert.productTypeChangeConfirmButton,
                                    style: .default) { (action) in
                                        completion(true)
                                    }
        alertController.addAction(cancel)
        alertController.addAction(confirm)
        present(alertController, animated: true)
    }

    /// Product Confirmation Delete alert
    ///
    func presentProductConfirmationDeleteAlert(completion: @escaping (_ isConfirmed: Bool) -> ()) {
        let alertController = UIAlertController(title: Localization.Alert.productDeleteConfirmationTitle,
                                                message: Localization.Alert.productDeleteConfirmationMessage,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localization.Alert.productDeleteConfirmationCancelButton,
                                   style: .cancel) { (action) in
                                       completion(false)
                                   }
        let confirm = UIAlertAction(title: Localization.Alert.productDeleteConfirmationConfirmButton,
                                    style: .default) { (action) in
                                        completion(true)
                                    }
        alertController.addAction(cancel)
        alertController.addAction(confirm)
        present(alertController, animated: true)
    }

    /// Variation Deletion Confirmation alert
    ///
    func presentVariationConfirmationDeleteAlert(completion: @escaping (_ isConfirmed: Bool) -> ()) {
        let alertController = UIAlertController(title: Localization.Alert.variationDeleteConfirmationTitle,
                                                message: Localization.Alert.variationDeleteConfirmationMessage,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localization.Alert.variationDeleteConfirmationCancelButton,
                                   style: .cancel) { (action) in
            completion(false)
        }
        let confirm = UIAlertAction(title: Localization.Alert.variationDeleteConfirmationConfirmButton,
                                    style: .default) { (action) in
            completion(true)
        }
        alertController.addAction(cancel)
        alertController.addAction(confirm)
        present(alertController, animated: true)
    }

    // MARK: - Progress

    /// Progress view for save action
    ///
    func showSavingProgress(for productStatus: ProductStatus) {
        switch productStatus {
        case .publish:
            displayInProgressView(title: Localization.ProgressView.productPublishingTitle, message: Localization.ProgressView.productPublishingMessage)
        default:
            displayInProgressView(title: Localization.ProgressView.productSavingTitle, message: Localization.ProgressView.productSavingMessage)
        }
    }

    /// Progress view for product deletion
    ///
    func showProductDeletionProgress() {
        displayInProgressView(title: Localization.ProgressView.productDeletionTitle, message: Localization.ProgressView.productDeletionMessage)
    }

    /// Progress view for variation deletion
    ///
    func showVariationDeletionProgress() {
        displayInProgressView(title: Localization.ProgressView.variationDeletionTitle, message: Localization.ProgressView.variationDeletionMessage)
    }
}

private extension ProductFormViewController {
    func displayInProgressView(title: String, message: String) {
        let viewProperties = InProgressViewProperties(title: title, message: message)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext

        navigationController?.present(inProgressViewController, animated: true, completion: nil)
    }
}

private enum Localization {
    enum Alert {
        // Product type change
        static let productTypeChangeTitle = NSLocalizedString("Are you sure you want to change the product type?",
                                                              comment: "Title of the alert when a user is changing the product type")
        static let productTypeChangeMessage = NSLocalizedString("Changing the product type will modify some of the product data",
                                                                comment: "Body of the alert when a user is changing the product type")
        static let productVariableTypeChangeMessage =
            NSLocalizedString("Changing the product type will modify some of the product data and delete all your attributes and variations",
                              comment: "Body of the alert when a user is changing the product type")

        static let productTypeChangeCancelButton =
            NSLocalizedString("Cancel", comment: "Cancel button on the alert when the user is cancelling the action on changing product type")
        static let productTypeChangeConfirmButton = NSLocalizedString("Yes, change",
                                                                      comment: "Confirmation button on the alert when the user is changing product type")

        // Product deletion
        static let productDeleteConfirmationTitle = NSLocalizedString("Remove product",
                                                                      comment: "Title of the alert when a user is moving a product to the trash")
        static let productDeleteConfirmationMessage = NSLocalizedString("Do you want to move this product to the Trash?",
                                                                        comment: "Body of the alert when a user is moving a product to the trash")
        static let productDeleteConfirmationCancelButton =
            NSLocalizedString("Cancel", comment: "Cancel button on the alert when the user is cancelling the action on moving a product to the trash")
        static let productDeleteConfirmationConfirmButton =
            NSLocalizedString("Move to Trash", comment: "Confirmation button on the alert when the user is moving a product to the trash")

        // Variation deletion
        static let variationDeleteConfirmationTitle = NSLocalizedString("Remove variation",
                                                                        comment: "Title of the alert when a user is deleting a variation")
        static let variationDeleteConfirmationMessage = NSLocalizedString("Are you sure you want to remove this variation?",
                                                                          comment: "Body of the alert when a user is deleting a variation")
        static let variationDeleteConfirmationCancelButton =
            NSLocalizedString("Cancel", comment: "Cancel button on the alert when the user is cancelling the action on deleting a variation")
        static let variationDeleteConfirmationConfirmButton =
            NSLocalizedString("Remove", comment: "Confirmation button on the alert when the user is deleting a variation")
    }

    enum ProgressView {
        static let productPublishingTitle = NSLocalizedString("Publishing your product...",
                                                              comment: "Title of the in-progress UI while updating the Product remotely")
        static let productPublishingMessage = NSLocalizedString("Please wait while we publish this product to your store",
                                                                comment: "Message of the in-progress UI while updating the Product remotely")

        static let productSavingTitle = NSLocalizedString("Saving your product...",
                                                          comment: "Title of the in-progress UI while saving a Product as draft remotely")
        static let productSavingMessage = NSLocalizedString("Please wait while we save this product to your store",
                                                            comment: "Message of the in-progress UI while saving a Product as draft remotely")

        static let productDeletionTitle = NSLocalizedString("Placing your product in the trash...",
                                                            comment: "Title of the in-progress UI while deleting the Product remotely")
        static let productDeletionMessage = NSLocalizedString("Please wait while we update your store details",
                                                              comment: "Message of the in-progress UI while deleting the Product remotely")

        static let variationDeletionTitle = NSLocalizedString("Removing your variation...",
                                                              comment: "Title of the in-progress UI while deleting the Variation remotely")
        static let variationDeletionMessage = NSLocalizedString("Please wait while we update your store details",
                                                                comment: "Message of the in-progress UI while deleting the Variation remotely")
    }
}
