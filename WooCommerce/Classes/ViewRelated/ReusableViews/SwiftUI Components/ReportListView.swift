import SwiftUI
import Yosemite

protocol ReportListPresentable {
    var items: [ReportItem] { get }
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

    var icon: Icon? {
        if let base64String = iconBase64,
           let imageData = Data(base64Encoded: base64String),
           let image = UIImage(data: imageData) {
            return .base64(image)
        } else if let url = URL(string: iconUrl) {
            return .remote(url)
        }
        return nil
    }
}

/// Represent a screen with a list of IconListItems. Mainly used to present reports such as What's New in WooCommerce.
///
struct ReportListView: View {
    let viewModel: ReportListPresentable
    private var isPad: Bool { UIDevice.isPad() }

    var body: some View {
        VStack {
            Spacer(minLength: isPad ? 40 : 75)
            LargeTitleView(text: viewModel.title)
            Spacer(minLength: isPad ? 32 : 40)
            ScrollView {
                ForEach(viewModel.items, id: \.id) {
                    IconListItem(title: $0.title,
                                 subtitle: $0.subtitle,
                                 icon: $0.icon)
                }
            }
            Spacer()
            Button(viewModel.ctaTitle, action: viewModel.onDismiss)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, isPad ? 40 : 24)
                .padding(.bottom, isPad ? 40 : 60)
        }
    }
}

// MARK: - Preview
struct ReportListView_Previews: PreviewProvider {
    static var features: [Feature] {
        let jsonData = try? JSONSerialization.data(withJSONObject: ["title": "foo",
                                                                    "subtitle": "bar",
                                                                    "iconBase64": "",
                                                                    "iconUrl": "https://s0.wordpress.com/i/store/mobile/plans-premium.png"],
                                                   options: .fragmentsAllowed)
        let feature = try? JSONDecoder().decode(Feature.self, from: jsonData ?? Data())
        return [feature, feature, feature].compactMap { $0 }
    }

    static var previews: some View {
        ReportListView(viewModel: WhatsNewViewModel(items: features, onDismiss: {}))
    }
}
