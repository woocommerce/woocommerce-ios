import SwiftUI

/// View model for a row in a list of domain suggestions.
struct DomainRowViewModel {
    /// The domain name is used for the selected state.
    let name: String
    /// Attributed name to be displayed in the row.
    let attributedName: AttributedString
    /// Attributed detail to be displayed in the row.
    let attributedDetail: AttributedString?
    /// Whether the domain is selected.
    let isSelected: Bool

    init(domainName: String, attributedDetail: AttributedString?, searchQuery: String, isSelected: Bool) {
        self.name = domainName
        self.attributedDetail = attributedDetail
        self.isSelected = isSelected
        self.attributedName = {
            var attributedName = AttributedString(domainName)
            attributedName.font = isSelected ? .body.bold(): .body
            attributedName.foregroundColor = .init(.label)

            if let rangeOfSearchQuery = attributedName
                .range(of: searchQuery
                    // Removes leading/trailing spaces in the search query.
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    // Removes spaces in the search query.
                    .split(separator: " ").joined()
                    .lowercased()) {
                attributedName[rangeOfSearchQuery].font = .body
                attributedName[rangeOfSearchQuery].foregroundColor = .init(.secondaryLabel)
            }
            return attributedName
        }()
    }
}

/// A row that shows an attributed domain name with a checkmark if the domain is selected.
struct DomainRowView: View {
    let viewModel: DomainRowViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Layout.spacingBetweenNameAndDetail) {
                Text(viewModel.attributedName)
                if let attributedDetail = viewModel.attributedDetail {
                    Text(attributedDetail)
                }
            }
            if viewModel.isSelected {
                Spacer()
                Image(uiImage: .checkmarkImage)
                    .foregroundColor(Color(.brand))
            }
        }
        .padding(Layout.insets)
    }
}

private extension DomainRowView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
        static let spacingBetweenNameAndDetail: CGFloat = 4
    }
}

struct DomainRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            DomainRowView(viewModel: .init(domainName: "whitechristmastrees.mywc.mysite",
                                           attributedDetail: nil,
                                           searchQuery: "White Christmas Trees",
                                           isSelected: true))
            DomainRowView(viewModel: .init(domainName: "whitechristmastrees.mywc.mysite",
                                           attributedDetail: nil,
                                           searchQuery: "White Christmas",
                                           isSelected: false))
        }
    }
}
