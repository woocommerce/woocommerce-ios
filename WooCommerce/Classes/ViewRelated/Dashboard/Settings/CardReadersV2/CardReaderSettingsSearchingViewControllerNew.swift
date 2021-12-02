import SwiftUI

/// This view controller is used when no reader is connected. It assists
/// the merchant in connecting to a reader.
///
final class CardReaderSettingsSearchingViewControllerNew: UIHostingController<CardReaderSettingsSearchingView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: CardReaderSettingsSearchingView());
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

struct CardReaderSettingsSearchingView: View {
    var body: some View {
        ScrollableVStack {
            Spacer()

            Text(Localization.connectYourCardReaderTitle)
                .font(.headline)
                .padding(.bottom, 32)
            Image(uiImage: .cardReaderConnect)
                .resizable()
                .scaledToFit()
                .frame(height: 206)
                .padding(.bottom, 32)

            Spacer()
        }.multilineTextAlignment(.center)
            .navigationTitle(Localization.title)
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
        CardReaderSettingsSearchingView()
    }
}
