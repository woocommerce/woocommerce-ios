import UIKit
import Yosemite

/// Displays one Product image with a delete action.
///
final class ProductImageViewController: UIViewController {
    typealias Deletion = (_ productImage: ProductImage) -> Void

    @IBOutlet private weak var imageView: UIImageView!

    private let productImage: ProductImage
    private let isDeletionEnabled: Bool
    private let productUIImageLoader: ProductUIImageLoader
    private let onDeletion: Deletion

    private var previousBarTintColor: UIColor?

    private var imageLoaderTask: Cancellable?

    init(productImage: ProductImage,
         isDeletionEnabled: Bool,
         productUIImageLoader: ProductUIImageLoader,
         onDeletion: @escaping Deletion) {
        self.productImage = productImage
        self.isDeletionEnabled = isDeletionEnabled
        self.productUIImageLoader = productUIImageLoader
        self.onDeletion = onDeletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        imageLoaderTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMainView()
        configureNavigation()
        configureImageView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previousBarTintColor = navigationController?.navigationBar.barTintColor
        navigationController?.navigationBar.barTintColor = .black
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.barTintColor = previousBarTintColor
        super.viewWillDisappear(animated)
    }
}

private extension ProductImageViewController {
    func configureMainView() {
        view.backgroundColor = .black
    }

    func configureNavigation() {
        guard isDeletionEnabled else {
            return
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .trashImage,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(deleteProductImage))
    }

    func configureImageView() {
        imageView.contentMode = Constants.imageContentMode
        imageView.clipsToBounds = Constants.clipToBounds

        imageLoaderTask = productUIImageLoader.requestImage(productImage: productImage) { [weak imageView] image in
            imageView?.image = image
        }
    }
}

private extension ProductImageViewController {
    @objc func deleteProductImage() {
        let title = NSLocalizedString("Remove Image",
                                      comment: "Title on the alert when the user taps to delete a Product image")
        let message = NSLocalizedString("Are you sure you want to remove this image?",
                                        comment: "Message on the alert when the user taps to delete a Product image")
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.view.tintColor = .text
        let cancel = UIAlertAction(title: NSLocalizedString(
            "Cancel",
            comment: "Dismiss button on the alert when the user taps to delete a Product image"
        ), style: .cancel, handler: nil)

        let delete = UIAlertAction(title: NSLocalizedString(
            "Remove",
            comment: "Confirm button on the alert when the user taps to delete a Product image"
        ), style: .destructive) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.onDeletion(self.productImage)
        }

        alert.addAction(cancel)
        alert.addAction(delete)

        ServiceLocator.analytics.track(.productImageSettingsDeleteImageButtonTapped)

        present(alert, animated: true, completion: nil)
    }
}

/// Constants
///
private extension ProductImageViewController {
    enum Constants {
        static let clipToBounds = true
        static let imageContentMode = UIView.ContentMode.scaleAspectFit
    }
}
