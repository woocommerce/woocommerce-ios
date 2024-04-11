import SwiftUI

/// View for store performance on Dashboard screen
///
struct StorePerformanceView: View {
    @ObservedObject private var viewModel: StorePerformanceViewModel

    init(viewModel: StorePerformanceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            header
        }
        .padding(Layout.padding)
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: Layout.strokeWidth)
        }
    }
}

private extension StorePerformanceView {
    var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Localization.title)
                    .headlineStyle()
            }
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    // TODO
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

private extension StorePerformanceView {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let strokeWidth: CGFloat = 0.5
    }

    enum Localization {
        static let title = NSLocalizedString(
            "storePerformanceView.title",
            value: "Performance",
            comment: "Title of the store performance section on the Dashboard screen"
        )
        static let hideCard = NSLocalizedString(
            "storePerformanceView.hideCard",
            value: "Hide this card",
            comment: "Menu item to dismiss the store performance section on the Dashboard screen"
        )
    }
}

#Preview {
    StorePerformanceView(viewModel: StorePerformanceViewModel())
}
