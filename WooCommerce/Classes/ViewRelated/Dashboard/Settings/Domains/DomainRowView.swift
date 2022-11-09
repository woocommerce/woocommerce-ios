import SwiftUI

/// View model for a row in a list of domain suggestions.
struct DomainRowViewModel: Identifiable, Equatable {
    var id: String {
        name
    }

    /// The domain name is used for the selected state.
    let name: String
    /// Attributed name to be displayed in the row.
    let attributedName: AttributedString

    init(domainName: String, searchQuery: String) {
        self.name = domainName
        // TODO-8045: update attributed name to highlight the selected text
        // and substring that matches the search query.
        self.attributedName = .init(domainName)
    }
}

/// A row that shows an attributed domain name with a checkmark if the domain is selected.
struct DomainRowView: View {
    let viewModel: DomainRowViewModel
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(viewModel.attributedName)
            if isSelected {
                Spacer()
                Image(uiImage: .checkmarkImage)
                    .foregroundColor(Color(.brand))
            }
        }
    }
}

struct DomainRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            DomainRowView(viewModel: .init(domainName: "whitechristmastrees.mywc.mysite", searchQuery: "White Christmas Trees"), isSelected: true)
            DomainRowView(viewModel: .init(domainName: "whitechristmastrees.mywc.mysite", searchQuery: "White Christmas"), isSelected: false)
        }
    }
}
