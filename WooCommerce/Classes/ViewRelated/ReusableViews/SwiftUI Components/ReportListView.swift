import SwiftUI

protocol ReportListConvertible {
    var items: [ReportItem] { get }
}

protocol ReportListPresentable {
    var title: String { get }
    var ctaTitle: String { get }
    var onDismiss: () -> Void { get }
}

struct ReportItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconUrl: String
    let iconBase64: String?

    var icon: UIImage? {
        guard let base64String = iconBase64 else { return nil }
        return Data(base64Encoded: base64String).flatMap { UIImage(data: $0) }
    }
}

struct ReportListView: View {
    let viewModel: ReportListConvertible & ReportListPresentable

    var body: some View {
        VStack {
            Spacer(minLength: 75)
            LargeTitleView(text: viewModel.title)
            Spacer(minLength: 40)
            ScrollView {
                ForEach(viewModel.items, id: \.title) {
                    IconListItem(title: $0.title,
                                 subtitle: $0.subtitle,
                                 iconUrl: $0.iconUrl,
                                 icon: $0.icon)
                }
            }
            Spacer()
            Button(viewModel.ctaTitle, action: viewModel.onDismiss)
                .frame(height: 50)
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            Spacer(minLength: 60)
        }
    }
}

struct ReportListView_Previews: PreviewProvider {
    static var previews: some View {
        ReportListView(viewModel: WhatsNewViewModel(items: [], onDismiss: {}))
    }
}
