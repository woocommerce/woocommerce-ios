import SwiftUI

struct LearnMoreRow: View {
    let localizedMarkdownString: String
    @State private var learnMoreURL: URL? = nil

    var body: some View {
        AttributedText(learnMoreAttributedString)
            .font(.subheadline)
            .attributedTextForegroundColor(Color(.textSubtle))
            .attributedTextLinkColor(Color(.textLink))
            .customOpenURL(binding: $learnMoreURL)
            .padding(.horizontal, Constants.horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: Constants.rowHeight, alignment: .leading)
            .safariSheet(url: $learnMoreURL)
    }

    private var learnMoreAttributedString: NSAttributedString {
        let learnMoreAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: 0
        ]

        let learnMoreAttrText = try! NSMutableAttributedString(markdown: localizedMarkdownString)
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
        LearnMoreRow(localizedMarkdownString: "[Learn more](https://pe.usps.com/text/imm/immc5_010.htm about Internal Transaction Number")
    }
}
