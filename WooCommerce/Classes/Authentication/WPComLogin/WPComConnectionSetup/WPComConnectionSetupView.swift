import SwiftUI
import UIKit

/// Hosting controller for `WPComConnectionSetupView`
final class WPComConnectionSetupHostingController: UIHostingController<WPComConnectionSetupView> {

    init(viewModel: WPComConnectionSetupViewModel) {
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
                        Text(Localization.title)
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
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                footer
                    .padding(Constants.contentPadding)
                    .background(Color(uiColor: .systemBackground))
                    .renderedIf(!dynamicTypeSize.isAccessibilitySize)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
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
        static let title = NSLocalizedString(
            "wpComConnectionSetupView.title",
            value: "Connect to WordPress.com",
            comment: "Title for the WPCom connection setup screen."
        )
        static let cancelButton = NSLocalizedString(
            "wpComConnectionSetupView.cancelButton",
            value: "Cancel",
            comment: "Cancel button title in the WPCom connection setup screen toolbar."
        )
    }
}

#Preview {
    let viewModel = WPComConnectionSetupViewModel(
        storeName: "coffeebeans.com",
        handler: PreviewSetupHandler(),
        onDismiss: {},
        onGoToStore: {},
        onUpdatePlugin: {}
    )
    WPComConnectionSetupView(viewModel: viewModel)
}

private final class PreviewSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    func start() {
        Task { @MainActor in
            delegate?.stepDidUpdate(.connect, status: .running)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            delegate?.stepDidUpdate(.connect, status: .success)

            delegate?.stepDidUpdate(.checkPlugin, status: .running)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            delegate?.stepDidUpdate(.checkPlugin, status: .success)

            delegate?.setupDidComplete()
        }
    }

    func retry() { start() }
    func cancel() {}
}
