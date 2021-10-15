import SwiftUI

struct LearnMoreRow: View {
    let content: String
    let contentURL: URL?
    @State private var displayedURL: URL?

    var body: some View {
        Button(action: {
            displayedURL = contentURL
        }, label: {
            Text(content)
                .font(.subheadline)
                .foregroundColor(Color(.textLink))
        })
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(maxWidth: .infinity, minHeight: Constants.rowHeight, alignment: .leading)
        .safariSheet(url: $displayedURL)
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
        LearnMoreRow(content: "Learn more about Internal Transaction Number", contentURL: URL(string: "https://pe.usps.com/text/imm/immc5_010.htm"))
    }
}
