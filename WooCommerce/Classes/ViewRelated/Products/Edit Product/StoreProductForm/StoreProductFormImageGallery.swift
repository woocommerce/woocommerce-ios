import StoreDesignSystem
import SwiftUI
import UIKit
import Yosemite

struct StoreProductFormImageGallery: UIViewRepresentable {
    let statuses: [ProductImageStatus]
    let isEditable: Bool
    let allowsMultiple: Bool
    let isVariation: Bool
    let imageLoader: ProductUIImageLoader
    let onAction: (ProductFormInlineAction) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = Layout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = StoreSpacing.s5
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor(Color.storeSurfaceBright)
        view.showsHorizontalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .never
        view.delegate = context.coordinator
        ProductImagesHeaderViewModel(productImageStatuses: [], config: .images).registerCollectionViewCells(view)
        return view
    }

    func updateUIView(_ view: UICollectionView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onAction = isEditable ? onAction : nil
        view.allowsSelection = isEditable
        let config = ProductImagesCellConfig(statuses: statuses,
                                             isEditable: isEditable,
                                             allowsMultiple: allowsMultiple,
                                             isVariation: isVariation)
        coordinator.update(view, statuses: statuses, config: config, imageLoader: imageLoader)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UICollectionView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite else { return nil }
        let category = UIContentSizeCategory(context.environment.dynamicTypeSize)
        let height = ProductImagesHeaderViewModel.cellSize(for: category).height
        return CGSize(width: width, height: min(height, width))
    }

    @MainActor
    final class Coordinator: NSObject, UICollectionViewDelegateFlowLayout {
        var onAction: ((ProductFormInlineAction) -> Void)?
        private var model: ProductImagesHeaderViewModel?
        private var dataSource: ProductImagesCollectionViewDataSource?

        func update(_ view: UICollectionView, statuses: [ProductImageStatus], config: ProductImagesCellConfig, imageLoader: ProductUIImageLoader) {
            guard model?.config != config || model?.productImageStatuses != statuses else { return }

            let model = ProductImagesHeaderViewModel(productImageStatuses: statuses, config: config)
            self.model = model
            let dataSource = ProductImagesCollectionViewDataSource(viewModel: model, productUIImageLoader: imageLoader)
            self.dataSource = dataSource
            view.dataSource = dataSource
            view.collectionViewLayout.invalidateLayout()
            view.reloadData()
            if model.shouldScrollToStart, !model.items.isEmpty, !view.bounds.isEmpty {
                view.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
            }
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let model, model.items.indices.contains(indexPath.item) else { return }
            collectionView.deselectItem(at: indexPath, animated: false)
            switch model.items[indexPath.item] {
            case .image(.uploadFailure(let asset, let error, _, _)):
                onAction?(.failedImageUpload(asset: asset, error: error))
            case .image, .addImage, .extendedAddImage:
                onAction?(.addImage)
            }
        }

        func collectionView(_ collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout,
                            sizeForItemAt indexPath: IndexPath) -> CGSize {
            let size = collectionView.bounds.size
            if case .extendedAddImages = model?.config { return size }
            return CGSize(width: size.height, height: size.height)
        }
    }

    private final class Layout: UICollectionViewFlowLayout {
        override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
            newBounds.size != collectionView?.bounds.size || super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }
    }
}
