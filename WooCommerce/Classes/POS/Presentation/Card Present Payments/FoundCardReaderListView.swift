import SwiftUI

/// Displays a list of card readers that are found, with a CTA to connect to a reader and a CTA to cancel reader search.
struct FoundCardReaderListView: View {
    private let readerIDs: [String]
    private let connect: (String) -> Void
    private let cancelSearch: () -> Void

    init(readerIDs: [String],
         connect: @escaping ((String) -> Void),
         cancelSearch: @escaping (() -> Void)) {
        self.readerIDs = readerIDs
        self.connect = connect
        self.cancelSearch = cancelSearch
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(SeveralReadersFoundViewController.Localization.headline)
                .font(.headline)
                .padding(Layout.headerPadding)

            List(readerIDs, id: \.self) { reader in
                HStack {
                    Text(reader)
                    Spacer()
                    Button(SeveralReadersFoundViewController.Localization.connect) {
                        connect(reader)
                    }
                    .buttonStyle(TextButtonStyle())
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)

            HStack(spacing: Layout.horizontalSpacing) {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
                Text(SeveralReadersFoundViewController.Localization.scanningLabel)
                Spacer()
            }

            Button(action: {
                cancelSearch()
            }) {
                Text(SeveralReadersFoundViewController.Localization.cancel)
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(Layout.buttonPadding)
        }
        .padding(Layout.padding)
    }
}

private extension FoundCardReaderListView {
    enum Layout {
        static let padding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let headerPadding: EdgeInsets = .init(top: 20, leading: 4, bottom: 20, trailing: 4)
        static let buttonPadding: EdgeInsets = .init(top: 16, leading: 0, bottom: 16, trailing: 0)
        static let horizontalSpacing: CGFloat = 16
    }
}

#Preview {
    FoundCardReaderListView(readerIDs: ["Reader 1", "Reader 2"],
                            connect: { _ in },
                            cancelSearch: {})
}
