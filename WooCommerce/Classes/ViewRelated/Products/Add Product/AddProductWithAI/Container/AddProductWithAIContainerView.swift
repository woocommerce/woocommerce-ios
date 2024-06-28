import SwiftUI

/// Hosting controller for `AddProductWithAIContainerView`
final class AddProductWithAIContainerHostingController: UIHostingController<AddProductWithAIContainerView> {
    private let viewModel: AddProductWithAIContainerViewModel
    private var addProductFromImageCoordinator: AddProductFromImageCoordinator?
    private var selectPackageImageCoordinator: SelectPackageImageCoordinator?

    init(viewModel: AddProductWithAIContainerViewModel) {
        self.viewModel = viewModel
        super.init(rootView: AddProductWithAIContainerView(viewModel: viewModel))
        rootView.onUsePackagePhoto = { [weak self] productName in
            self?.presentPackageFlow(productName: productName)
        }
        rootView.onPickPackagePhoto = { [weak self] source in
            self?.presentImageSelectionFlow(source: source)
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
        navigationController?.presentationController?.delegate = self
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension AddProductWithAIContainerHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return viewModel.canBeDismissed
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.dismiss(animated: true)
        })
    }
}

private extension AddProductWithAIContainerHostingController {
    /// Presents the image to product flow to detect product details from image using AI
    ///
    func presentPackageFlow(productName: String?) {
        guard let navigationController else {
            return
        }
        let coordinator = AddProductFromImageCoordinator(siteID: viewModel.siteID,
                                                         source: viewModel.source,
                                                         productName: productName,
                                                         sourceNavigationController: navigationController,
                                                         onAIGenerationCompleted: { [weak self] data in
            self?.viewModel.didGenerateDataFromPackage(data)
        })
        self.addProductFromImageCoordinator = coordinator
        coordinator.start()
    }

    /// Presents the image selection flow to select package photo
    ///
    func presentImageSelectionFlow(source: MediaPickingSource) {
        guard let navigationController else {
            return
        }
        let coordinator = SelectPackageImageCoordinator(siteID: viewModel.siteID,
                                                        mediaSource: source,
                                                        sourceNavigationController: navigationController,
                                                        onImageSelected: { [weak self] image in
            self?.viewModel.didSelectImage(image)
        })
        selectPackageImageCoordinator = coordinator
        coordinator.start()
    }
}

/// Container view for the product creation with AI flow.
struct AddProductWithAIContainerView: View {
    /// Closure invoked when the close button is pressed
    ///
    var onUsePackagePhoto: (String?) -> Void = { _ in }
    var onPickPackagePhoto: (MediaPickingSource) -> Void = { _ in }

    @ObservedObject private var viewModel: AddProductWithAIContainerViewModel

    init(viewModel: AddProductWithAIContainerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.featureFlagService.isFeatureFlagEnabled(.productCreationAIv2M1) == false {
                progressView
            }

            switch viewModel.currentStep {
            case .productName:
                if viewModel.featureFlagService.isFeatureFlagEnabled(.productCreationAIv2M1) {
                    ProductCreationAIStartingInfoView(viewModel: viewModel.startingInfoViewModel,
                                                      onPickPackagePhoto: onPickPackagePhoto,
                                                      onContinueWithFeatures: { features in
                        withAnimation {
                            viewModel.onProductFeaturesAdded(features: features)
                        }
                    })
                } else {
                    AddProductNameWithAIView(viewModel: viewModel.addProductNameViewModel,
                                             onUsePackagePhoto: onUsePackagePhoto,
                                             onContinueWithProductName: { name in
                        withAnimation {
                            viewModel.onContinueWithProductName(name: name)
                        }
                    })
                }
            case .aboutProduct:
                AddProductFeaturesView(viewModel: .init(siteID: viewModel.siteID,
                                                        productName: viewModel.productName,
                                                        productFeatures: viewModel.productFeatures) { features in
                    withAnimation {
                        viewModel.onProductFeaturesAdded(features: features)
                    }
                })
            case .preview:
                ProductDetailPreviewView(viewModel: .init(siteID: viewModel.siteID,
                                                          productName: viewModel.productName,
                                                          productDescription: viewModel.productDescription,
                                                          productFeatures: viewModel.productFeatures) { product in
                    viewModel.didCreateProduct(product)
                }, onDismiss: {
                    viewModel.backtrackOrDismiss()
                })
            }
        }
        .onAppear() {
            viewModel.onAppear()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    withAnimation {
                        viewModel.backtrackOrDismiss()
                    }
                }, label: {
                    if viewModel.currentStep.previousStep == nil {
                        Text(Localization.cancel)
                    } else {
                        Image(systemName: "chevron.backward")
                            .headlineLinkStyle()
                    }
                })
            }
        }
    }
}


private extension AddProductWithAIContainerView {
    var progressView: some View {
        ProgressView(value: viewModel.currentStep.progress)
            .frame(height: Layout.ProgressView.height)
            .tint(.init(uiColor: .accent))
            .progressViewStyle(.linear)
    }
}

private extension AddProductWithAIContainerView {
    enum Localization {
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the AI product creation flow.")
    }


    enum Layout {
        enum ProgressView {
            static let height: CGFloat = 2
        }
    }
}

struct AddProductWithAIContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductWithAIContainerView(viewModel: .init(siteID: 123,
                                                       source: .storeOnboarding,
                                                       onCancel: { },
                                                       onCompletion: { _ in }))
    }
}
