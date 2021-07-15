import Foundation
import SwiftUI
import AttributedText

final class CardReaderSettingsUnknownViewController: UIHostingController<CardReaderSettingsUnknownView>, CardReaderSettingsViewModelPresenter {
    func configure(viewModel: CardReaderSettingsPresentedViewModel) {
        guard let viewModel = viewModel as? CardReaderSettingsUnknownViewModel else {
            DDLogError("Unexpectedly unable to downcast to CardReaderSettingsUnknownViewModel")
            return
        }
        rootView.viewModel = viewModel
    }

    init(viewModel: CardReaderSettingsUnknownViewModel) {
        super.init(rootView: CardReaderSettingsUnknownView(viewModel: viewModel))
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct CardReaderSettingsUnknownView: View {
    @State var viewModel: CardReaderSettingsUnknownViewModel
    @State var presentedURL: URL? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(Localization.connectYourCardReaderTitle)
                    .font(.headline)
                    .frame(height: 90)

                Image("card-reader-connect")

                NumberedListItem(number: Localization.hintOneTitle, content: Localization.hintOne)
                NumberedListItem(number: Localization.hintTwoTitle, content: Localization.hintTwo)
                NumberedListItem(number: Localization.hintThreeTitle, content: Localization.hintThree)

                Spacer()

                Button(action: {}) {
                    Text(Localization.connectButton)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                HStack(alignment: .center, spacing: 20) {
                    Image(uiImage: .infoOutlineImage)
                        .accentColor(Color(.lightGray))
                        .frame(width: 20, height: 20)
                    AttributedText(Localization.learnMore)
                        .accentColor(Color(.textLink))
                        .customOpenURL(binding: $presentedURL)
                }
            }
            .safariSheet(url: $presentedURL)
            .padding(.horizontal, 20)
            .navigationTitle(Localization.title)
        }
    }
}

private struct NumberedListItem: View {
    let number: String
    let content: String

    var body: some View {
        HStack(spacing: 19) {
            Text(number)
                .frame(width: 32, height: 32)
                .background(Color(.gray(.shade0)))
                .cornerRadius(16)
            Text(content)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .font(.callout)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Localization
//
private extension CardReaderSettingsUnknownView {
    enum Localization {
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

        static var learnMore: NSAttributedString {
            let learnMoreText = NSLocalizedString(
                "<a href=\"https://woocommerce.com/payments\">Learn more</a> about accepting payments with your mobile device and ordering card readers",
                comment: "A label prompting users to learn more about card readers with an embedded hyperlink"
            )

            let learnMoreAttributes: [NSAttributedString.Key: Any] = [
                .font: StyleManager.footerLabelFont,
                .foregroundColor: UIColor.textSubtle
            ]

            let learnMoreAttrText = NSMutableAttributedString()
            learnMoreAttrText.append(learnMoreText.htmlToAttributedString)
            let range = NSRange(location: 0, length: learnMoreAttrText.length)
            learnMoreAttrText.addAttributes(learnMoreAttributes, range: range)

            return learnMoreAttrText
        }
    }
}


struct CardReaderSettingsUnknownView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderSettingsUnknownView(viewModel: CardReaderSettingsUnknownViewModel(didChangeShouldShow: { _ in }))
    }
}
