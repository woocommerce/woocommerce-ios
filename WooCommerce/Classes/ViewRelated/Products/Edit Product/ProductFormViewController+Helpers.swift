import UIKit

/// ProductFormViewController Helpers
///
extension ProductFormViewController {

    // MARK: - Alert

    /// Product Type Change alert
    ///
    func presentProductTypeChangeAlert(completion: @escaping (Bool) -> ()) {
        let title = NSLocalizedString("Are you sure you want to change the product type?",
                                      comment: "Title of the alert when a user is changing the product type")
        let body = NSLocalizedString("Changing the product type will modify some of the product data",
                                     comment: "Body of the alert when a user is changing the product type")
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
}
