import SwiftUI

/// This view controller is used when no reader is connected. It assists
/// the merchant in connecting to a reader.
///
final class CardReaderSettingsSearchingViewController: UIHostingController<CardReaderSettingsSearchingView>, CardReaderSettingsViewModelPresenter {
    /// If we know reader(s), begin search automatically once each time this VC becomes visible
    ///
    private var didBeginSearchAutomatically = false

    private var viewModel: CardReaderSettingsSearchingViewModel?


    /// Connection Controller (helps connect readers)
    ///
    private lazy var connectionController: CardReaderConnectionController? = {
        guard let siteID = viewModel?.siteID else {
            return nil
        }

        guard let knownReaderProvider = viewModel?.knownReaderProvider else {
            return nil
        }

        return CardReaderConnectionController(
            forSiteID: siteID,
            knownReaderProvider: knownReaderProvider,
            alertsProvider: CardReaderSettingsAlerts()
        )
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: CardReaderSettingsSearchingView())
        rootView.connectClickAction = {
            self.searchAndConnect()
        }
        rootView.showURL = {url in
            WebviewHelper.launch(url, with: self)
        }
    }

    /// Accept our viewmodel and listen for changes on it
    ///
    func configure(viewModel: CardReaderSettingsPresentedViewModel) {
        self.viewModel = viewModel as? CardReaderSettingsSearchingViewModel

        guard self.viewModel != nil else {
            DDLogError("Unexpectedly unable to downcast to CardReaderSettingsSearchingViewModel")
            return
        }

        self.viewModel?.didUpdate = onViewModelDidUpdate
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        maybeBeginSearchAutomatically()
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel?.didUpdate = nil
        didBeginSearchAutomatically = false
        super.viewWillDisappear(animated)
    }
}

// MARK: - View Updates
//
private extension CardReaderSettingsSearchingViewController {
    func onViewModelDidUpdate() {
        maybeBeginSearchAutomatically()
    }

    func maybeBeginSearchAutomatically() {
        /// If we've already begun search automattically since this view appeared, don't do it again
        ///
        guard !didBeginSearchAutomatically else {
            return
        }

        /// Make sure there is no reader connected
        ///
        let noReaderConnected = viewModel?.noConnectedReader == .isTrue
        guard noReaderConnected else {
            return
        }

        /// Make sure we have a known reader
        ///
        guard let hasKnownReader = viewModel?.hasKnownReader(), hasKnownReader else {
            return
        }

        searchAndConnect()
        didBeginSearchAutomatically = true
    }
}

// MARK: - Convenience Methods
//
private extension CardReaderSettingsSearchingViewController {
    func searchAndConnect() {
        connectionController?.searchAndConnect(from: self) {_ in
            /// No need for logic here. Once connected, the connected reader will publish
            /// through the `cardReaderAvailableSubscription`
        }
    }
}

struct CardReaderSettingsSearchingView: View {
    var connectClickAction: (() -> Void)? = nil
    var showURL: ((URL) -> Void)? = nil

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isCompat: Bool {
        get {
            verticalSizeClass == .compact
        }
    }

    var body: some View {
        VStack {
            Spacer()

            Text(Localization.connectYourCardReaderTitle)
                .font(.headline)
                .padding(.bottom, isCompat ? 16 : 32)
            Image(uiImage: .cardReaderConnect)
                .resizable()
                .scaledToFit()
                .frame(height: isCompat ? 80 : 206)
                .padding(.bottom, isCompat ? 16 : 32)

            Hint(title: Localization.hintOneTitle, text: Localization.hintOne)
            Hint(title: Localization.hintTwoTitle, text: Localization.hintTwo)
            Hint(title: Localization.hintThreeTitle, text: Localization.hintThree)

            Spacer()

            Button(Localization.connectButton, action: connectClickAction!)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 8)

            InPersonPaymentsLearnMore()
                .customOpenURL(action: {url in showURL?(url)})
        }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .padding()
            .if(isCompat) {content in
                ScrollView(.vertical) {
                    content
                }
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
        "Manage Card Reader",
        comment: "Settings > Manage Card Reader > Title for the no-reader-connected screen in settings."
    )

    static let connectYourCardReaderTitle = NSLocalizedString(
        "Connect your card reader",
        comment: "Settings > Manage Card Reader > Prompt user to connect their first reader"
    )

    static let hintOneTitle = NSLocalizedString(
        "1",
        comment: "Settings > Manage Card Reader > Connect > Help hint number 1"
    )

    static let hintOne = NSLocalizedString(
        "Make sure card reader is charged",
        comment: "Settings > Manage Card Reader > Connect > Hint to charge card reader"
    )

    static let hintTwoTitle = NSLocalizedString(
        "2",
        comment: "Settings > Manage Card Reader > Connect > Help hint number 2"
    )

    static let hintTwo = NSLocalizedString(
        "Turn card reader on and place it next to mobile device",
        comment: "Settings > Manage Card Reader > Connect > Hint to power on reader"
    )

    static let hintThreeTitle = NSLocalizedString(
        "3",
        comment: "Settings > Manage Card Reader > Connect > Help hint number 3"
    )

    static let hintThree = NSLocalizedString(
        "Turn mobile device Bluetooth on",
        comment: "Settings > Manage Card Reader > Connect > Hint to enable Bluetooth"
    )

    static let connectButton = NSLocalizedString(
        "Connect Card Reader",
        comment: "Settings > Manage Card Reader > Connect > A button to begin a search for a reader"
    )

    static let learnMore = NSLocalizedString(
        "Tap to learn more about accepting payments with your mobile device and ordering card readers",
        comment: "A label prompting users to learn more about card readers"
    )
}

struct CardReaderSettingsSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderSettingsSearchingView(connectClickAction: {})
    }
}
