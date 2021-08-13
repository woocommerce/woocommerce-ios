import SwiftUI

struct LearnMoreRow: View {
    let localizedStringWithHyperlink: String
    @State private var learnMoreURL: URL? = nil

    var body: some View {
        AttributedText(learnMoreAttributedString)
            .accentColor(Color(.textLink))
            .customOpenURL(binding: $learnMoreURL)
            .padding(.horizontal, Constants.horizontalPadding)
            .frame(minHeight: Constants.rowHeight)
            .safariSheet(url: $learnMoreURL)
    }

    private var learnMoreAttributedString: NSAttributedString {
        let learnMoreAttributes: [NSAttributedString.Key: Any] = [
            .font: StyleManager.subheadlineFont,
            .foregroundColor: UIColor.textSubtle,
            .underlineStyle: 0
        ]

        let learnMoreAttrText = NSMutableAttributedString()
        learnMoreAttrText.append(localizedStringWithHyperlink.htmlToAttributedString)
        let range = NSRange(location: 0, length: learnMoreAttrText.length)
        learnMoreAttrText.addAttributes(learnMoreAttributes, range: range)

        return learnMoreAttrText
    }
}

private extension LearnMoreRow {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let rowHeight: CGFloat = 44
    }
}

struct LearnMoreRow_Previews: PreviewProvider {
    static var previews: some View {
        LearnMoreRow(localizedStringWithHyperlink: "<a href=\"https://pe.usps.com/text/imm/immc5_010.htm\">Learn more</a> about Internal Transaction Number")
    }
}
