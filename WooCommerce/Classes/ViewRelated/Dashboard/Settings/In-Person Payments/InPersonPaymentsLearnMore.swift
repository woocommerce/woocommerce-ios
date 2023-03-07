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

struct InPersonPaymentsLearnMore_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLearnMore()
            .padding()
    }
}
