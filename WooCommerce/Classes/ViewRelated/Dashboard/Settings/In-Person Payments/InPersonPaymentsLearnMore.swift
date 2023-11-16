import SwiftUI

struct InPersonPaymentsLearnMore: View {
    @Environment(\.customOpenURL) var customOpenURL

    @ObservedObject private var viewModel: LearnMoreViewModel
    private let showInfoIcon: Bool

    init(viewModel: LearnMoreViewModel = LearnMoreViewModel(),
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
            AttributedText(viewModel.learnMoreAttributedString)
        }
        .accessibilityHint(viewModel.learnMoreAttributedString.string)
        .accessibilityAction(named: Localization.toggleEnableCashOnDeliveryLearnMoreAccessibilityAction) {
            viewModel.learnMoreTapped()
            customOpenURL?(viewModel.url)
        }
        .onTapGesture {
            viewModel.learnMoreTapped()
            customOpenURL?(viewModel.url)
        }
    }

    var iconSize: CGFloat {
        UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 20)
    }
}

struct InPersonPaymentsLearnMore_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLearnMore()
            .padding()
    }
}



extension InPersonPaymentsLearnMore {
    enum Localization {
        static let toggleEnableCashOnDeliveryLearnMoreAccessibilityAction = NSLocalizedString(
            "menu.payments.payInPerson.learnMore.link.accessibilityAction",
            value: "Learn more",
            comment: "Title for the accessibility action to open the learn more screen, showing information " +
            "about adding Pay in Person to their checkout.")
    }
}
