import SwiftUI
import Yosemite

final class SetUpTapToPayOnboardingViewController: UIHostingController<SetUpTapToPayOnboardingView>, PaymentSettingsFlowViewModelPresenter {

    private let onWillDisappear: (() -> ())?

    init(viewModel: InPersonPaymentsViewModel,
         onWillDisappear: (() -> ())?) {
        self.onWillDisappear = onWillDisappear
        let onboardingView = InPersonPaymentsView(viewModel: viewModel)
        super.init(rootView: SetUpTapToPayOnboardingView(onboardingView: onboardingView))
        rootView.cancelTapped = { [weak self] in
            self?.dismiss(animated: true)
        }

        viewModel.showSupport = { [weak self] in
            guard let self = self else { return }
            let supportForm = SupportFormHostingController(viewModel: .init())
            supportForm.show(from: self)
        }

        viewModel.showURL = { [weak self] url in
            guard let self = self else { return }
            WebviewHelper.launch(url, with: self)
        }
    }

    convenience init?(viewModel: PaymentSettingsFlowPresentedViewModel) {
        guard let viewModel = viewModel as? InPersonPaymentsViewModel else {
            return nil
        }
        self.init(viewModel: viewModel, onWillDisappear: nil)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        onWillDisappear?()
        super.viewWillDisappear(animated)
    }
}

struct SetUpTapToPayOnboardingView: View {
    @State var onboardingView: InPersonPaymentsView
    var cancelTapped: (() -> Void)? = nil

    var body: some View {
        VStack {
            HStack {
                Button(Localization.cancelButton) {
                    cancelTapped?()
                }
                .padding(.top)

                Spacer()
            }
            .padding()

            Spacer()

            onboardingView
        }
    }
}

private enum Localization {
    static let cancelButton = NSLocalizedString(
        "Cancel",
        comment: "Settings > Set up Tap to Pay on iPhone > Onboarding > Cancel button")
}
