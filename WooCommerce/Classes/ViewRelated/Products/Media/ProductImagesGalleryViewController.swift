import UIKit
import Yosemite
import Photos

/// Displays Product images in sequence, with a delete action.
///
final class ProductImagesGalleryViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!

    private var productImages: [ProductImage]

    // If present, the collection view will initially show the image at the selected index
    private var selectedIndex: Int?
    private let productUIImageLoader: ProductUIImageLoader
    private let onDeletion: ProductImageViewController.Deletion

    private var previousBarTintColor: UIColor?

    // The index of the current visible image
    private var currentImageIndex: Int? {
        return collectionView.indexPathsForVisibleItems.first?.item
    }


    init(images: [ProductImage],
         selectedIndex: Int? = nil,
         productUIImageLoader: ProductUIImageLoader,
         onDeletion: @escaping ProductImageViewController.Deletion) {
        self.productImages = images
        self.selectedIndex = selectedIndex
        self.productUIImageLoader = productUIImageLoader
        self.onDeletion = onDeletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMainView()
        configureNavigation()
        configureCollectionView()
        registerCells()

        scrollToSelectedIndex(index: selectedIndex)
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

    private func scrollToSelectedIndex(index: Int?) {
        if let selectedIndex = index {
            let indexPath = IndexPath(item: selectedIndex, section: 0)
            DispatchQueue.main.async {
                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }
}

private extension ProductImagesGalleryViewController {
    func configureMainView() {
        view.backgroundColor = .black
    }

    func configureNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .trashImage,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(deleteProductImage))
    }

    func configureCollectionView() {
        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        if let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            collectionViewLayout.scrollDirection = .horizontal
            collectionViewLayout.minimumLineSpacing = 0
            collectionViewLayout.minimumInteritemSpacing = 0
            //collectionViewLayout.itemSize = collectionView.frame.size
        }
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    func registerCells() {
        collectionView.register(ProductImageCollectionViewCell.loadNib(), forCellWithReuseIdentifier: ProductImageCollectionViewCell.reuseIdentifier)
        collectionView.register(InProgressProductImageCollectionViewCell.loadNib(),
                                forCellWithReuseIdentifier: InProgressProductImageCollectionViewCell.reuseIdentifier)
    }
}

// MARK: Actions
private extension ProductImagesGalleryViewController {
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
            if let index = self.currentImageIndex {
                self.onDeletion(self.productImages[index])
                self.productImages.remove(at: index)
                self.collectionView.reloadData()
            }

            if self.productImages.count == 0 {
                self.navigationController?.popViewController(animated: true)
            }
        }

        alert.addAction(cancel)
        alert.addAction(delete)

        ServiceLocator.analytics.track(.productImageSettingsDeleteImageButtonTapped)

        present(alert, animated: true, completion: nil)
    }
}

// MARK: CollectionView DataSource
//
extension ProductImagesGalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let image = productImages[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductImageCollectionViewCell.reuseIdentifier,
                                                      for: indexPath)
        configureRemoteImageCell(cell, productImage: image)
        return cell
    }

}

extension ProductImagesGalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }

    // Scroll to the right index every time viewWillTransitionToSize is called.
    // Then performBatchUpdates to adjust our layout.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        scrollToSelectedIndex(index: currentImageIndex)
        collectionView.reloadData()
    }
}

// MARK: Cell configuration
//
private extension ProductImagesGalleryViewController {

    func configureRemoteImageCell(_ cell: UICollectionViewCell, productImage: ProductImage) {
        guard let cell = cell as? ProductImageCollectionViewCell else {
            fatalError()
        }

        cell.backgroundColor = .black
        cell.imageView.contentMode = .center
        cell.imageView.image = .productsTabProductCellPlaceholderImage
        cell.contentView.layer.borderWidth = 0

        let cancellable = productUIImageLoader.requestImage(productImage: productImage) { [weak cell] image in
            cell?.imageView.contentMode = .scaleAspectFit
            cell?.imageView.image = image
        }
        cell.cancellableTask = cancellable
    }
}
