import ConfettiSwiftUI
import SwiftUI
import struct Yosemite.Product

final class FirstProductCreatedHostingController: UIHostingController<FirstProductCreatedView> {
    /// The coordinator for sharing products
    ///
    private var shareProductCoordinator: ShareProductCoordinator?

    init(siteID: Int64,
         productURL: URL,
         productName: String,
         productDescription: String,
         showShareProductButton: Bool) {
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton)
        super.init(rootView: FirstProductCreatedView(viewModel: viewModel))
        viewModel.launchAISharingFlow = { [weak self] in
            guard let self,
                  let navigationController = self.navigationController else {
                return
            }

            let shareProductCoordinator = ShareProductCoordinator(siteID: siteID,
                                                                  productURL: productURL,
                                                                  productName: productName,
                                                                  productDescription: productDescription,
                                                                  shareSheetAnchorView: self.view,
                                                                  navigationController: navigationController)
            shareProductCoordinator.start()
            self.shareProductCoordinator = shareProductCoordinator
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
        ServiceLocator.analytics.track(.firstCreatedProductShown)
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
    }
}

private extension FirstProductCreatedHostingController {
    enum Localization {
        static let cancel = NSLocalizedString("Dismiss", comment: "Button to dismiss the first created product screen")
    }
}

/// Celebratory screen after creating the first product 🎉
///
struct FirstProductCreatedView: View {
    @ObservedObject private var viewModel: FirstProductCreatedViewModel

    init(viewModel: FirstProductCreatedViewModel) {
        self.viewModel = viewModel
    }

    @State private var confettiCounter: Int = 0

    var body: some View {
        GeometryReader { proxy in
            ScrollableVStack(spacing: Constants.verticalSpacing) {
                Spacer()
                Text(Localization.title)
                    .titleStyle()
                Image(uiImage: .welcomeImage)
                Text(Localization.message)
                    .secondaryBodyStyle()
                    .multilineTextAlignment(.center)

                Button(Localization.shareAction,
                       action: {
                    viewModel.didTapShareProduct()
                })
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .renderedIf(viewModel.showShareProductButton)
                .sharePopover(isPresented: $viewModel.isSharePopoverPresented) {
                    viewModel.shareSheet
                }
                .shareSheet(isPresented: $viewModel.isShareSheetPresented) {
                    viewModel.shareSheet
                }

                Spacer()
            }
            .padding()
            .confettiCannon(counter: $confettiCounter,
                            num: Constants.confettiCount,
                            rainHeight: proxy.size.height,
                            radius: proxy.size.width)
        }
        .onAppear {
            confettiCounter += 1
        }
        .background(Color(uiColor: .systemBackground))
    }
}

private extension FirstProductCreatedView {
    enum Constants {
        static let verticalSpacing: CGFloat = 40
        static let confettiCount: Int = 100
    }
    enum Localization {
        static let title = NSLocalizedString(
            "First product created 🎉",
            comment: "Title of the celebratory screen after creating the first product"
        )
        static let message = NSLocalizedString(
            "Congratulations! You're one step closer to getting the new store ready.",
            comment: "Message on the celebratory screen after creating first product"
        )
        static let shareAction = NSLocalizedString(
            "Share Product",
            comment: "Title of the action button to share the first created product"
        )
    }
}

struct FirstProductCreatedView_Previews: PreviewProvider {
    static var previews: some View {
        FirstProductCreatedView(viewModel: .init(productURL: URL(string: "https://example.com/sampleproduct")!,
                                                 productName: "Sample product",
                                                 showShareProductButton: true))
        .environment(\.colorScheme, .light)

        FirstProductCreatedView(viewModel: .init(productURL: URL(string: "https://example.com/sampleproduct")!,
                                                 productName: "Sample product",
                                                 showShareProductButton: false))
        .environment(\.colorScheme, .light)

        FirstProductCreatedView(viewModel: .init(productURL: URL(string: "https://example.com/sampleproduct")!,
                                                 productName: "Sample product",
                                                 showShareProductButton: false))
        .environment(\.colorScheme, .dark)
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
