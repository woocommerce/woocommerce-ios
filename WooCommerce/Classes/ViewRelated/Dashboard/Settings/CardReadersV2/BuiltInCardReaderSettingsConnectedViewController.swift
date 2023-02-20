import Foundation
import UIKit
import SwiftUI
import Yosemite
import Combine

/// This view controller is used when a reader is currently connected. It assists
/// the merchant in updating and/or disconnecting from the reader, as needed.
///
final class BuiltInCardReaderSettingsConnectedViewController: UIHostingController<BuiltInCardReaderSettingsConnectedView>, CardReaderSettingsViewModelPresenter {

    /// ViewModel
    ///
    private var viewModel: BuiltInCardReaderSettingsConnectedViewModel? {
        didSet {
            if let viewModel = viewModel {
                rootView.viewModel = viewModel
                rootView.connectClickAction = viewModel.startTestPayment
            }
        }
    }

    private let settingsAlerts = CardReaderSettingsAlerts()



    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: BuiltInCardReaderSettingsConnectedView(viewModel: BuiltInCardReaderSettingsConnectedViewModel(didChangeShouldShow: { _ in }, configuration: .init(country: "US"), analyticsTracker: CardReaderConnectionAnalyticsTracker(configuration: .init(country: "US")))))
        rootView.connectClickAction = viewModel?.startTestPayment
        rootView.rootViewController = self
    }

    /// Accept our viewmodel
    ///
    func configure(viewModel: CardReaderSettingsPresentedViewModel) {
        self.viewModel = viewModel as? BuiltInCardReaderSettingsConnectedViewModel

        guard self.viewModel != nil else {
            DDLogError("Unexpectedly unable to downcast to CardReaderSettingsConnectedViewModel")
            return
        }

        self.viewModel?.didUpdate = onViewModelDidUpdate
    }

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        rootView.rootViewController = navigationController
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel?.didUpdate = nil
        super.viewWillDisappear(animated)
    }
}

// MARK: - View Configuration
//
private extension BuiltInCardReaderSettingsConnectedViewController {
    func onViewModelDidUpdate() {
        // no-op
    }

    /// Returns `false` if no reader update is available or if  `viewModel` is `nil`.
    /// Returns `true` otherwise.
    ///
    func isReaderUpdateAvailable() -> Bool {
        viewModel?.optionalReaderUpdateAvailable == true
    }

    /// Set the title and back button.
    ///
    func configureNavigation() {
        title = Localization.title
    }
}

struct BuiltInCardReaderSettingsConnectedView: View {
    @ObservedObject var viewModel: BuiltInCardReaderSettingsConnectedViewModel

    var rootViewController: UIViewController?

    var connectClickAction: (() -> Void)? = nil

    var showURL: ((URL) -> Void)? = nil
    var learnMoreUrl: URL? = nil

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.sizeCategory) private var sizeCategory

    var isCompact: Bool {
        get {
            verticalSizeClass == .compact
        }
    }

    var isSizeCategoryLargeThanExtraLarge: Bool {
        sizeCategory >= .accessibilityMedium
    }

    var body: some View {
        VStack {
            Spacer()

            Text(Localization.connectYourCardReaderTitle)
                .font(.headline)
                .padding(.bottom, isCompact ? 16 : 32)
            Image(systemName: "checkmark.circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(.systemGreen))
                .scaledToFit()
                .font(.system(size: isCompact ? 40 : 120))
                .padding(.bottom, isCompact ? 16 : 32)

            Hint(title: Localization.hintOneTitle, text: Localization.hintOne)
            Hint(title: Localization.hintTwoTitle, text: Localization.hintTwo)
            Hint(title: Localization.hintThreeTitle, text: Localization.hintThree)

            Spacer()

            Button(Localization.connectButton, action: connectClickAction!)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 8)

            InPersonPaymentsLearnMore()
                .customOpenURL(action: { url in
                    switch url {
                    case LearnMoreViewModel.learnMoreURL:
                        if let url = learnMoreUrl {
                            showURL?(url)
                        }
                    default:
                        showURL?(url)
                    }
                })
            LazyNavigationLink(destination: summaryView(), isActive: Binding<Bool>(
                get: { viewModel.summaryActive },
                set: {
                        // $0 is the new Bool value of the toggle
                        // Your code for updating the model, or whatever
                        print("value: \($0)")
                    })) {
                EmptyView()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding()
        .if(isCompact || isSizeCategoryLargeThanExtraLarge) { content in
            ScrollView(.vertical) {
                content
            }
        }
        .wooNavigationBarStyle()
    }

    /// Returns a `SimplePaymentsSummary` instance when the view model is available.
    ///
    private func summaryView() -> some View {
        Group {
            if let summaryViewModel = viewModel.summaryViewModel {
                SimplePaymentsSummary(dismiss: {
                    let vc = summaryViewModel.orderLoaderViewController()
                    rootViewController?.show(vc, sender: nil)
                }, rootViewController: rootViewController, viewModel: summaryViewModel)
            }
            EmptyView()
        }
    }
}

private struct Hint: View {
    let title: String
    let text: String

    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .padding(.all, 12)
                .background(Color(UIColor.systemGray6))
                .clipShape(Circle())
            Text(text)
                .font(.callout)
                .padding(.leading, 16)
            Spacer()
        }
            .padding(.horizontal, 8)
    }
}

// MARK: - Localization
//
private enum Localization {
    static let title = NSLocalizedString(
        "Tap to Pay on iPhone",
        comment: "Settings > Manage Card Reader > Title for the no-reader-connected screen in settings."
    )

    static let connectYourCardReaderTitle = NSLocalizedString(
        "Collect card payments with your phone",
        comment: "Settings > Manage Card Reader > Prompt user to try a Tap to Pay on iPhone payment"
    )

    static let hintOneTitle = NSLocalizedString(
        "1",
        comment: "Settings > Tap to Pay on iPhone > Try it > Help hint number 1"
    )

    static let hintOne = NSLocalizedString(
        "Your phone is ready for Tap to Pay on iPhone!",
        comment: "Settings > Tap to Pay on iPhone > Try it > Hint that the phone is set up"
    )

    static let hintTwoTitle = NSLocalizedString(
        "2",
        comment: "Settings > Tap to Pay on iPhone > Try it > Help hint number 2"
    )

    static let hintTwo = NSLocalizedString(
        "View an order, Collect Payment, and choose Tap to Pay on iPhone",
        comment: "Settings > Tap to Pay on iPhone > Try it > Hint to collect payment"
    )

    static let hintThreeTitle = NSLocalizedString(
        "3",
        comment: "Settings > Tap to Pay on iPhone > Try it > Help hint number 3"
    )

    static let hintThree = NSLocalizedString(
        "Your customer can tap their card on your phone to pay",
        comment: "Settings > Tap to Pay on iPhone > Try it > Hint to tap card"
    )

    static let connectButton = NSLocalizedString(
        "Try a payment",
        comment: "Settings > Tap to Pay on iPhone > Try it > A button to begin a search for a reader"
    )

    static let learnMore = NSLocalizedString(
        "Tap to learn more about accepting payments using Tap to Pay on iPhone",
        comment: "A label prompting users to learn more about Tap to Pay on iPhone"
    )
}

struct BuiltInCardReaderSettingsConnectedView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderSettingsSearchingView(connectClickAction: {})
    }
}
