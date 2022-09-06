import SwiftUI

struct InPersonPaymentsLearnMore: View {
    @Environment(\.customOpenURL) var customOpenURL

    private let viewModel: LearnMoreViewModel

    init(viewModel: LearnMoreViewModel = LearnMoreViewModel()) {
        self.viewModel = viewModel
    }

    private let cardPresentConfiguration = CardPresentConfigurationLoader().configuration

    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: .infoOutlineImage)
                .resizable()
                .foregroundColor(Color(.neutral(.shade60)))
                .frame(width: iconSize, height: iconSize)
            AttributedText(viewModel.learnMoreAttributedString)
        }
            .padding(.vertical, Constants.verticalPadding)
            .onTapGesture {
                viewModel.learnMoreTapped()
                customOpenURL?(viewModel.url)
            }
    }

    var iconSize: CGFloat {
        UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 20)
    }
}

private enum Constants {
    static let verticalPadding: CGFloat = 8
}

private enum Localization {
    static let unavailable = NSLocalizedString(
        "In-Person Payments is currently unavailable",
        comment: "Title for the error screen when In-Person Payments is unavailable"
    )

    static let acceptCash = NSLocalizedString(
        "You can still accept in-person cash payments by enabling the “Cash on Delivery” payment method on your store.",
        comment: "Generic error message when In-Person Payments is unavailable"
    )

    static let learnMoreText = NSLocalizedString(
        "%1$@ about accepting payments with your mobile device and ordering card readers",
        comment: """
                 A label prompting users to learn more about card readers"
                 %1$@ is a placeholder that always replaced with \"Learn more\" string,
                 which should be translated separately and considered part of this sentence.
                 """
    )
}

struct InPersonPaymentsLearnMore_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLearnMore()
            .padding()
    }
}
