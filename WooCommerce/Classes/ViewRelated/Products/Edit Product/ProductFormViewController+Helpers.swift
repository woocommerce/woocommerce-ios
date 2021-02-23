import UIKit
import Yosemite

/// ProductFormViewController Helpers
///
extension ProductFormViewController {

    // MARK: - Alert

    /// Product Type Change alert
    ///
    func presentProductTypeChangeAlert(for productType: ProductType, completion: @escaping (Bool) -> ()) {
        let title = NSLocalizedString("Are you sure you want to change the product type?",
                                      comment: "Title of the alert when a user is changing the product type")

        let body: String
        switch productType {
        case .variable:
            body = NSLocalizedString("Changing the product type will modify some of the product data and delete all your attributes and variations",
                                     comment: "Body of the alert when a user is changing the product type")
        default:
            body = NSLocalizedString("Changing the product type will modify some of the product data",
                                     comment: "Body of the alert when a user is changing the product type")
        }

        let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button on the alert when the user is cancelling the action on changing product type")
        let confirmButton = NSLocalizedString("Yes, change", comment: "Confirmation button on the alert when the user is changing product type")
        let alertController = UIAlertController(title: title,
                                                message: body,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: cancelButton,
                                   style: .cancel) { (action) in
                                       completion(false)
                                   }
        let confirm = UIAlertAction(title: confirmButton,
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
        let title = NSLocalizedString("Remove product",
                                      comment: "Title of the alert when a user is moving a product to the trash")
        let body = NSLocalizedString("Do you want to move this product to the Trash?",
                                     comment: "Body of the alert when a user is moving a product to the trash")
        let cancelButton = NSLocalizedString("Cancel",
                                             comment: "Cancel button on the alert when the user is cancelling the action on moving a product to the trash")
        let confirmButton = NSLocalizedString("Move to Trash",
                                              comment: "Confirmation button on the alert when the user is moving a product to the trash")
        let alertController = UIAlertController(title: title,
                                                message: body,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: cancelButton,
                                   style: .cancel) { (action) in
                                       completion(false)
                                   }
        let confirm = UIAlertAction(title: confirmButton,
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
        let title = NSLocalizedString("Remove variation",
                                      comment: "Title of the alert when a user is deleting a variation")
        let body = NSLocalizedString("Are you sure you want to remove this variation?",
                                     comment: "Body of the alert when a user is deleting a variation")
        let cancelButton = NSLocalizedString("Cancel",
                                             comment: "Cancel button on the alert when the user is cancelling the action on deleting a variation")
        let confirmButton = NSLocalizedString("Remove",
                                              comment: "Confirmation button on the alert when the user is deleting a variation")
        let alertController = UIAlertController(title: title,
                                                message: body,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: cancelButton,
                                   style: .cancel) { (action) in
            completion(false)
        }
        let confirm = UIAlertAction(title: confirmButton,
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
        let title: String
        let message: String

        switch productStatus {
        case .publish:
            title = NSLocalizedString("Publishing your product...", comment: "Title of the in-progress UI while updating the Product remotely")
            message = NSLocalizedString("Please wait while we publish this product to your store",
                                        comment: "Message of the in-progress UI while updating the Product remotely")
        default:
            title = NSLocalizedString("Saving your product...", comment: "Title of the in-progress UI while saving a Product as draft remotely")
            message = NSLocalizedString("Please wait while we save this product to your store",
                                        comment: "Message of the in-progress UI while saving a Product as draft remotely")
        }
        displayInProgressView(title: title, message: message)
    }

    /// Progress view for product deletion
    ///
    func showProductDeletionProgress() {
        let title = NSLocalizedString("Placing your product in the trash...", comment: "Title of the in-progress UI while deleting the Product remotely")
        let message = NSLocalizedString("Please wait while we update your store details",
                                        comment: "Message of the in-progress UI while deleting the Product remotely")
        displayInProgressView(title: title, message: message)
    }

    /// Progress view for variation deletion
    ///
    func showVariationDeletionProgress() {
        let title = NSLocalizedString("Removing your variation...", comment: "Title of the in-progress UI while deleting the Variation remotely")
        let message = NSLocalizedString("Please wait while we update your store details",
                                        comment: "Message of the in-progress UI while deleting the Variation remotely")
        displayInProgressView(title: title, message: message)
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
