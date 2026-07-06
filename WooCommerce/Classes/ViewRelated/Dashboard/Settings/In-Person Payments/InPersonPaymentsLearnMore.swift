import SwiftUI

struct InPersonPaymentsLearnMore: View {
    @Environment(\.customOpenURL) var customOpenURL

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
            Text(attributedLearnMoreText)
                .environment(\.openURL, OpenURLAction { url in
                    guard url == viewModel.url else {
                        return .systemAction
                    }

                    viewModel.learnMoreTapped()
                    customOpenURL?(url)
                    return .handled
                })
                .accessibilityHint(learnMoreText)
        }
    }

    var iconSize: CGFloat {
        UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 20)
    }

    private var attributedLearnMoreText: AttributedString {
        var attributedText = AttributedString(learnMoreText)
        attributedText.font = .footnote
        attributedText.foregroundColor = .init(uiColor: .textSubtle)

        if let range = attributedText.range(of: viewModel.linkText) {
            let linkAttributes = AttributeContainer()
                .link(viewModel.url)
                .foregroundColor(.init(uiColor: .textLink))
            attributedText[range].mergeAttributes(linkAttributes)
        }

        return attributedText
    }

    private var learnMoreText: String {
        .localizedStringWithFormat(viewModel.formatText, viewModel.linkText)
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
