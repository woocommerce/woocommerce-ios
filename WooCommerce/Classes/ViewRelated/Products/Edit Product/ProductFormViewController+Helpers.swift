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

    enum ProductSavedAlertType {
        case saved
        case draftSaved
        case published
        case copied

        var alertTitle: String {
            switch self {
            case .saved:
                return Localization.Alert.productSavedAlert
            case .draftSaved:
                return Localization.Alert.productDraftSavedAlert
            case .published:
                return Localization.Alert.productPublishedAlert
            case .copied:
                return Localization.Alert.productCopiedAlert
            }
        }
    }

    /// Product Confirmation Save alert
    ///
    func presentProductConfirmationSaveAlert(type: ProductSavedAlertType = .saved) {
        let contextNoticePresenter: NoticePresenter = {
            let noticePresenter = DefaultNoticePresenter()
            noticePresenter.presentingViewController = self
            return noticePresenter
        }()
        contextNoticePresenter.enqueue(notice: .init(title: type.alertTitle))
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

    /// Progress view for save action.
    ///
    func showSavingProgress(_ messageType: SaveMessageType) {
        switch messageType {
        case .publish:
            displayInProgressView(title: Localization.ProgressView.productPublishingTitle, message: Localization.ProgressView.productPublishingMessage)
        case .save:
            displayInProgressView(title: Localization.ProgressView.productSavingTitle, message: Localization.ProgressView.productSavingMessage)
        case .saveVariation:
            displayInProgressView(title: Localization.ProgressView.productVariationTitle, message: Localization.ProgressView.productVariationMessage)
        case .duplicate:
            displayInProgressView(title: Localization.ProgressView.productDuplicatingTitle, message: Localization.ProgressView.productDuplicatingMessage)
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
        inProgressViewController.modalPresentationStyle = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInProductsTab) ?
            .overFullScreen: .overCurrentContext

        navigationController?.present(inProgressViewController, animated: true, completion: nil)
    }
}

private enum Localization {
    enum Alert {
        // Product saved or updated
        static let productSavedAlert = NSLocalizedString("Product saved",
                                                         comment: "Title of the alert when a user is saving a product")
        static let productDraftSavedAlert = NSLocalizedString("Product draft saved",
                                                              comment: "Title of the alert when a user is saving a product draft")
        static let productPublishedAlert = NSLocalizedString("Product published",
                                                             comment: "Title of the alert when a user is publishing a product")
        static let productCopiedAlert = NSLocalizedString("Product copied", comment: "Title of the alert when a user has copied a product")

        // Product type change
        static let productTypeChangeTitle = NSLocalizedString("Are you sure you want to change the product type?",
                                                              comment: "This text appears as the title of a confirmation alert dialog that displays when a user attempts to change the type of a product they are editing (e.g., from simple product to variable product). The alert warns the user about the consequences of this action and requires confirmation before proceeding.")
        static let productTypeChangeMessage = NSLocalizedString("Changing the product type will modify some of the product data",
                                                                comment: "This text appears as the body message in an alert dialog that warns users when they attempt to change a product's type in the product editing screen, explaining that some product data will be modified as a result of this change.")
        static let productVariableTypeChangeMessage =
            NSLocalizedString("Changing the product type will modify some of the product data and delete all your attributes and variations",
                              comment: "This text appears as the body message of a confirmation alert dialog that warns users when they are changing a product type from variable to another type in the product editor. It explains the consequences of the action - that some product data will be modified and all attributes and variations will be permanently deleted.")

        static let productTypeChangeCancelButton =
            NSLocalizedString("Cancel", comment: "Button text used to dismiss action sheets, web views, and modal screens in authentication flows, including the store picker screen, Jetpack setup, and site credential login screens.")
        static let productTypeChangeConfirmButton = NSLocalizedString("Yes, change",
                                                                      comment: "Confirmation button on the alert when the user is changing product type")

        // Product deletion
        static let productDeleteConfirmationTitle = NSLocalizedString("Remove product",
                                                                      comment: "Title of the alert when a user is moving a product to the trash")
        static let productDeleteConfirmationMessage = NSLocalizedString("Do you want to move this product to the Trash?",
                                                                        comment: "Body of the alert when a user is moving a product to the trash")
        static let productDeleteConfirmationCancelButton =
            NSLocalizedString("Cancel", comment: "Button text used to dismiss action sheets, web views, and modal screens in authentication flows, including the store picker screen, Jetpack setup, and site credential login screens.")
        static let productDeleteConfirmationConfirmButton =
            NSLocalizedString("Move to Trash", comment: "Confirmation button on the alert when the user is moving a product to the trash")

        // Variation deletion
        static let variationDeleteConfirmationTitle = NSLocalizedString("Remove variation",
                                                                        comment: "Title of the alert when a user is deleting a variation")
        static let variationDeleteConfirmationMessage = NSLocalizedString("Are you sure you want to remove this variation?",
                                                                          comment: "This text appears as the body message in a confirmation alert dialog when a user attempts to delete a product variation in the WooCommerce store management app. The alert asks the user to confirm their intention before permanently removing the variation from their product.")
        static let variationDeleteConfirmationCancelButton =
            NSLocalizedString("Cancel", comment: "Button text used to dismiss action sheets, web views, and modal screens in authentication flows, including the store picker screen, Jetpack setup, and site credential login screens.")
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

        static let productDuplicatingTitle = NSLocalizedString("Duplicating your product...",
                                                               comment: "Title of the in-progress UI while duplicating a Product remotely")
        static let productDuplicatingMessage = NSLocalizedString("Please wait while we save a copy of this product to your store",
                                                                 comment: "Message of the in-progress UI while duplicating a Product as draft remotely")

        static let productDeletionTitle = NSLocalizedString("Placing your product in the trash...",
                                                            comment: "Title of the in-progress UI while deleting the Product remotely")
        static let productDeletionMessage = NSLocalizedString("Please wait while we update your store details",
                                                              comment: "Message of the in-progress UI while deleting the Product remotely")

        static let variationDeletionTitle = NSLocalizedString("Removing your variation...",
                                                              comment: "Title of the in-progress UI while deleting the Variation remotely")
        static let variationDeletionMessage = NSLocalizedString("Please wait while we update your store details",
                                                                comment: "Message of the in-progress UI while deleting the Variation remotely")
        static let productVariationTitle = NSLocalizedString("Saving your variation...",
                                                          comment: "Title of the in-progress UI while saving a Variation remotely")
        static let productVariationMessage = NSLocalizedString("Please wait while we save your latest changes",
                                                            comment: "Message of the in-progress UI while saving a Variation remotely")
    }
}
