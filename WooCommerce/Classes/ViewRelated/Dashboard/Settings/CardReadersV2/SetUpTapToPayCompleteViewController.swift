import SwiftUI

/// This view controller is used when no reader is connected. It assists
/// the merchant in connecting to a reader.
///
final class SetUpTapToPayCompleteViewController: UIHostingController<SetUpTapToPayCompleteView>, PaymentSettingsFlowViewModelPresenter {

    private var viewModel: SetUpTapToPayCompleteViewModel

    init?(viewModel: PaymentSettingsFlowPresentedViewModel) {
        guard let viewModel = viewModel as? SetUpTapToPayCompleteViewModel else {
            return nil
        }
        self.viewModel = viewModel

        super.init(rootView: SetUpTapToPayCompleteView(viewModel: viewModel))

        configureViewModel()
    }

    private func configureViewModel() {
        viewModel.dismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel.didUpdate = nil
        super.viewWillDisappear(animated)
    }
}

struct SetUpTapToPayCompleteView: View {
    @ObservedObject var viewModel: SetUpTapToPayCompleteViewModel

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isCompact: Bool {
        verticalSizeClass == .compact
    }

    var imageMaxHeight: CGFloat {
        isCompact ? Constants.maxCompactImageHeight : Constants.maxImageHeight
    }

    var imageFontSize: CGFloat {
        isCompact ? Constants.maxCompactImageHeight : Constants.imageFontSize
    }

    var body: some View {
        ScrollableVStack(padding: 0) {
            Image(systemName: "checkmark.circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(.systemGreen))
                .scaledToFit()
                .frame(maxHeight: imageMaxHeight)
                .font(.system(size: imageFontSize))
                .padding()

            Text(Localization.setUpCompleteTitle)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding()
                .fixedSize(horizontal: false, vertical: true)

            Text(Localization.setUpCompleteDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text(Localization.setUpCompleteDetail)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
                .fixedSize(horizontal: false, vertical: true)

            Button(Localization.doneButton, action: {
                viewModel.doneTapped()
            })
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
}

private enum Constants {
    static let maxImageHeight: CGFloat = 180
    static let maxCompactImageHeight: CGFloat = 80
    static let imageFontSize: CGFloat = 120
    static let compactImageFontSize: CGFloat = 40
}

// MARK: - Localization
//
private extension SetUpTapToPayCompleteView {
    enum Localization {
        static let setUpCompleteTitle = NSLocalizedString(
            "Set up complete",
            comment: "Settings > Set up Tap to Pay on iPhone > Complete > Inform user that " +
            "Tap to Pay on iPhone is ready"
        )

        static let setUpCompleteDescription = NSLocalizedString(
            "Your phone is ready for Tap to Pay on iPhone. Your customer can tap their card or " +
            "device on your phone to pay.",
            comment: "Settings > Set up Tap to Pay on iPhone > Complete > Description"
        )

        static let setUpCompleteDetail = NSLocalizedString(
            "You can find Tap to Pay on iPhone in Menu > Payments > Collect Payment, or from " +
            "Order Details. Choose Tap to Pay on iPhone as the payment method.",
            comment: "Settings > Set up Tap to Pay on iPhone > Complete > Detail"
        )

        static let doneButton = NSLocalizedString(
            "Done",
            comment: "Settings > Set up Tap to Pay on iPhone > Complete > A button to move to the " +
            "next for testing Tap to Pay on iPhone"
        )
    }
}

struct SetUpTapToPayCompleteView_Previews: PreviewProvider {
    static var previews: some View {

        let config = CardPresentConfigurationLoader().configuration
        let viewModel = SetUpTapToPayCompleteViewModel(
            didChangeShouldShow: nil,
            connectionAnalyticsTracker: .init(configuration: config))
        SetUpTapToPayCompleteView(viewModel: viewModel)
    }
}
