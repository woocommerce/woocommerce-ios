import SwiftUI

/// Hosting controller for `AddProductWithAIContainerView`
final class AddProductWithAIContainerHostingController: UIHostingController<AddProductWithAIContainerView> {
    private let siteID: Int64
    private let source: AddProductCoordinator.Source
    private var addProductFromImageCoordinator: AddProductFromImageCoordinator?

    init(viewModel: AddProductWithAIContainerViewModel) {
        siteID = viewModel.siteID
        source = viewModel.source
        super.init(rootView: AddProductWithAIContainerView(viewModel: viewModel))

        viewModel.presentPackageFlow = presentPackageFlow
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
    func presentPackageFlow(onAIGenerationCompleted: @escaping (AddProductFromImageData?) -> Void) {
        guard let navigationController else {
            return
        }
        let coordinator = AddProductFromImageCoordinator(siteID: siteID,
                                                         source: source,
                                                         sourceNavigationController: navigationController,
                                                         onAIGenerationCompleted: onAIGenerationCompleted)
        self.addProductFromImageCoordinator = coordinator
        coordinator.start()
    }
}

/// Container view for the product creation with AI flow.
struct AddProductWithAIContainerView: View {

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
                                                          onUsePackagePhoto: viewModel.onUsePackagePhoto,
                                                          onContinueWithProductName: viewModel.onContinueWithProductName))
            default:
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
                                                       onCompletion: { }))
    }
}
