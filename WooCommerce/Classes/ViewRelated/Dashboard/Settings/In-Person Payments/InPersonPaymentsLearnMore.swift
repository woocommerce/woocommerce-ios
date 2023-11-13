import SwiftUI

struct InPersonPaymentsLearnMore: View {
    @Environment(\.customOpenURL) var customOpenURL

    private let viewModel: LearnMoreViewModel
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
                .renderedIf(showInfoIcon)
            AttributedText(viewModel.learnMoreAttributedString)
        }
        .accessibilityAddTraits(.isButton)
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
