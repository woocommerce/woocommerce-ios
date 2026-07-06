import SwiftUI

struct InPersonPaymentsLearnMore: View {
    @Environment(\.customOpenURL) private var customOpenURL
    @Environment(\.openURL) private var openURL

    @ObservedObject private var viewModel: LearnMoreViewModel
    private let showInfoIcon: Bool

    init(viewModel: LearnMoreViewModel,
         showInfoIcon: Bool = true) {
        self.viewModel = viewModel
        self.showInfoIcon = showInfoIcon
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: .infoOutlineImage)
                .resizable()
                .foregroundColor(Color(.neutral(.shade60)))
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
                .renderedIf(showInfoIcon)
            LearnMoreAttributedText(format: viewModel.formatText,
                                    tappableLearnMoreText: viewModel.linkText,
                                    url: viewModel.url,
                                    shouldUnderLine: false,
                                    textColor: .textSubtle,
                                    linkTextColor: .textLink,
                                    onTapURL: { url in
                                        openLearnMore(url: url)
                                    })
                .accessibilityAction(named: Localization.learnMoreAccessibilityAction) {
                    openLearnMore(url: viewModel.url)
                }
        }
    }

    var iconSize: CGFloat {
        UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 20)
    }

    private func openLearnMore(url: URL) {
        viewModel.learnMoreTapped()
        if let customOpenURL {
            customOpenURL(url)
        } else {
            openURL(url)
        }
    }
}

struct InPersonPaymentsLearnMore_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLearnMore(viewModel: .inPersonPayments(source: .paymentMethods,
                                                               paymentGateway: .wcPay),
                                  showInfoIcon: true)
            .padding()
    }
}

extension InPersonPaymentsLearnMore {
    enum Localization {
        static let learnMoreAccessibilityAction = NSLocalizedString(
            "menu.payments.payInPerson.learnMore.link.accessibilityAction",
            value: "Learn more",
            comment: "Title for the accessibility action to open the learn more screen, showing information " +
            "about adding Pay in Person to their checkout.")
    }
}
