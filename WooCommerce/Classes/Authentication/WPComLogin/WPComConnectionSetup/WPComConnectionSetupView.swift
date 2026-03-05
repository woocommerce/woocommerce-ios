import SwiftUI
import UIKit
import Combine
import Yosemite

/// Hosting controller for `WPComConnectionSetupView`
final class WPComConnectionSetupHostingController: UIHostingController<WPComConnectionSetupView> {

    private let viewModel: WPComConnectionSetupViewModel
    private var connectionWebView: UINavigationController?
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: WPComConnectionSetupViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WPComConnectionSetupView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}

struct WPComConnectionSetupView: View {
    @ObservedObject var viewModel: WPComConnectionSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    ConnectWPComHeaderView()
                    VStack(alignment: .leading, spacing: Constants.headerVerticalSpacing) {
                        Text(viewModel.title)
                            .largeTitleStyle()
                            .bold()
                        Text(viewModel.subtitleAttributedString)
                    }
                    VStack(alignment: .leading, spacing: Constants.stepsVerticalSpacing) {
                        ForEach(viewModel.steps) { step in
                            WPComConnectionSetupStepView(step: step)
                        }
                    }
                }

                Spacer()

                if dynamicTypeSize.isAccessibilitySize {
                    footer
                }
            }
            .padding(Constants.contentPadding)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        viewModel.cancelTapped()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Localization.getHelpButton) {
                        viewModel.getHelpTapped()
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                footer
                    .padding(Constants.contentPadding)
                    .background(Color(uiColor: .systemBackground))
                    .renderedIf(!dynamicTypeSize.isAccessibilitySize)
            }
        }
        .sheet(isPresented: $viewModel.isShowingGetHelp) {
            helpAndSupportView
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    var helpAndSupportView: some View {
        ViewControllerContainer(Self.makeHelpAndSupportController())
    }

    private static func makeHelpAndSupportController() -> UIViewController {
        let identifier = HelpAndSupportViewController.classNameWithoutNamespaces
        let helpVC = UIStoryboard.settings.instantiateViewController(identifier: identifier) { coder in
            HelpAndSupportViewController(sourceTag: WPComConnectionSetupViewModel.supportSourceTag, coder: coder)
        }
        helpVC.displaysDismissAction = true
        return WooNavigationController(rootViewController: helpVC)
    }

    @ViewBuilder var footer: some View {
        VStack {
            Button(viewModel.primaryButtonTitle) {
                viewModel.primaryButtonTapped()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.isPrimaryButtonEnabled)

            Button(viewModel.secondaryButtonTitle) {
                viewModel.secondaryButtonTapped()
            }
            .buttonStyle(SecondaryButtonStyle())
            .renderedIf(viewModel.isShowingSecondaryButton)
        }
    }
}

private extension WPComConnectionSetupView {
    enum Constants {
        static let contentVerticalSpacing: CGFloat = 32
        static let stepsVerticalSpacing: CGFloat = 32
        static let headerVerticalSpacing: CGFloat = 24
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let cancelButton = NSLocalizedString(
            "wpComConnectionSetupView.cancelButton",
            value: "Cancel",
            comment: "Cancel button title in the WPCom connection setup screen toolbar."
        )
        static let getHelpButton = NSLocalizedString(
            "wpComConnectionSetupView.getHelpButton",
            value: "Get help",
            comment: "Get help button title in the WPCom connection setup screen toolbar."
        )
    }
}

#Preview {
    let viewModel = WPComConnectionSetupViewModel(
        storeName: "coffeebeans.com",
        handler: WPComConnectionSetupHandler(
            siteID: 123,
            siteURL: "https://example.com",
            siteAlreadyConnected: false
        ),
        onDismiss: {},
        onGoToStore: {},
        onUpdatePlugin: { _ in }
    )
    WPComConnectionSetupView(viewModel: viewModel)
}
