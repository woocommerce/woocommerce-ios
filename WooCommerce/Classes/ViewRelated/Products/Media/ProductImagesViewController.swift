import UIKit
import Yosemite

/// Displays Product images with edit functionality.
///
final class ProductImagesViewController: UIViewController {
    typealias Completion = (_ images: [ProductImage]) -> Void

    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonBottomBorderView: UIView!
    @IBOutlet private weak var imagesContainerView: UIView!

    private let siteID: Int64
    private let productID: Int64
    private var productImages: [ProductImage] {
        didSet {
            imagesViewController.updateProductImages(productImages)
        }
    }

    // Child view controller.
    private lazy var imagesViewController: ProductImagesCollectionViewController = {
        let viewController = ProductImagesCollectionViewController(images: productImages,
                                                                   onDeletion: onDeletion)
        return viewController
    }()

    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        self.siteID = product.siteID
        self.productID = product.productID
        self.productImages = product.images
        self.onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMainView()
        configureNavigation()
        configureAddButton()
        configureAddButtonBottomBorderView()
        configureImagesContainerView()
    }
}

// MARK: - UI configurations
//
private extension ProductImagesViewController {
    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func configureNavigation() {
        title = NSLocalizedString("Photos", comment: "Product images (Product images page title)")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeEditing))

        removeNavigationBackBarButtonText()
    }

    func configureAddButton() {
        addButton.setTitle(NSLocalizedString("ADD PHOTOS", comment: "Action to add photos on the Product images screen"), for: .normal)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        addButton.applyPrimaryButtonStyle()
    }

    func configureAddButtonBottomBorderView() {
        addButtonBottomBorderView.backgroundColor = .systemColor(.separator)
    }

    func configureImagesContainerView() {
        imagesContainerView.backgroundColor = .basicBackground

        addChild(imagesViewController)
        imagesContainerView.addSubview(imagesViewController.view)
        imagesViewController.didMove(toParent: self)

        imagesViewController.view.translatesAutoresizingMaskIntoConstraints = false
        imagesContainerView.pinSubviewToSafeArea(imagesViewController.view)
    }
}

// MARK: - Actions
//
private extension ProductImagesViewController {

    @objc func addTapped() {
        // TODO-1713: display options to add an image.
    }

    @objc func completeEditing() {
        onCompletion(productImages)
    }

    func onDeletion(productImage: ProductImage) {
        productImages.removeAll(where: { $0.imageID == productImage.imageID })
        navigationController?.popViewController(animated: true)
    }
}
