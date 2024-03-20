import SwiftUI

struct CustomersListView: View {
    var body: some View {
        List {
            HStack {
                TitleAndSubtitleAndDetailRow(title: "Guest", subtitle: "guest@example.com")
                DisclosureIndicator()
            }
            HStack {
                TitleAndSubtitleAndDetailRow(title: "John Smith", detail: "jsmith", subtitle: "jsmith@example.com")
                DisclosureIndicator()
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
    }
}

private extension CustomersListView {
    enum Localization {
        static let title = NSLocalizedString("customersList.title",
                                             value: "Customers",
                                             comment: "Title for Customers list screen")
    }
}

#Preview {
    CustomersListView()
}
