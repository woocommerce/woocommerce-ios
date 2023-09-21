import SwiftUI

/// Hosting controller for `AddProductWithAIContainerView`
final class AddProductWithAIContainerHostingController: UIHostingController<AddProductWithAIContainerView> {
    private let viewModel: AddProductWithAIContainerViewModel
    private var addProductFromImageCoordinator: AddProductFromImageCoordinator?
    private var setToneAndVoiceBottomSheetPresenter: BottomSheetPresenter?

    init(viewModel: AddProductWithAIContainerViewModel) {
        self.viewModel = viewModel
        super.init(rootView: AddProductWithAIContainerView(viewModel: viewModel))
        rootView.onUsePackagePhoto = { [weak self] productName in
            self?.presentPackageFlow(productName: productName)
        }
        rootView.onSetToneAndVoice = presentSetToneAndVoice
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
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

    /// Presents the tone and voice sheet
    /// 
    func presentSetToneAndVoice() {
        guard let navigationController else {
            return
        }
        setToneAndVoiceBottomSheetPresenter = buildBottomSheetPresenter()
        let controller = AIToneVoiceHostingController(viewModel: .init(siteID: viewModel.siteID))
        setToneAndVoiceBottomSheetPresenter?.present(controller, from: navigationController)
    }

    // MARK: Bottom sheet helpers
    //
    func buildBottomSheetPresenter() -> BottomSheetPresenter {
        BottomSheetPresenter(configure: { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .none
            sheet.prefersGrabberVisible = true
            sheet.detents = [.medium(), .large()]
        })
    }
}

/// Container view for the product creation with AI flow.
struct AddProductWithAIContainerView: View {
    /// Closure invoked when the close button is pressed
    ///
    var onUsePackagePhoto: (String?) -> Void = { _ in }

    /// Closure invoked when the "Set tone and voice" button is pressed
    ///
    var onSetToneAndVoice: () -> Void = {  }

    @ObservedObject private var viewModel: AddProductWithAIContainerViewModel

    init(viewModel: AddProductWithAIContainerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            progressView

            switch viewModel.currentStep {
            case .productName:
                AddProductNameWithAIView(viewModel: .init(siteID: viewModel.siteID,
                                                          onUsePackagePhoto: onUsePackagePhoto,
                                                          onContinueWithProductName: { name in
                    withAnimation {
                        viewModel.onContinueWithProductName(name: name)
                    }
                }))
            case .aboutProduct:
                AddProductFeaturesView(viewModel: .init(siteID: viewModel.siteID,
                                                        productName: viewModel.productName,
                                                        onSetToneAndVoice: onSetToneAndVoice) {
                    withAnimation {
                        viewModel.onProductDetailsCreated()
                    }
                })
            case .preview:
                // TODO: Add other AI views
               Text("Add other AI views")
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
                                                       source: .productOnboarding,
                                                       onCancel: { },
                                                       onCompletion: { _ in }))
    }
}
