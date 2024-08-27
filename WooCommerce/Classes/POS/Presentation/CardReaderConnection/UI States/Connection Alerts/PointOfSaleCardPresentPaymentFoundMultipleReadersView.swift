import SwiftUI

/// Displays a list of card readers that are found, with a CTA to connect to a reader and a CTA to cancel reader search.
struct PointOfSaleCardPresentPaymentFoundMultipleReadersView: View {
    private let readerIDs: [String]
    private let connect: (String) -> Void
    private let cancelSearch: () -> Void

    init(viewModel: PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel) {
        self.readerIDs = viewModel.readerIDs
        self.connect = viewModel.connect
        self.cancelSearch = viewModel.cancelSearch
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(Localization.headline)
                .font(.posTitleEmphasized)
                .padding(Layout.headerPadding)
                .accessibilityAddTraits(.isHeader)

            List(readerIDs, id: \.self) { readerID in
                VStack {
                    readerRow(readerID: readerID)

                    if readerID == readerIDs.last {
                        scanningText()
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)

            Button(action: {
                cancelSearch()
            }) {
                Text(Localization.cancel)
            }
            .buttonStyle(POSSecondaryButtonStyle())
            .padding(Layout.buttonPadding)
        }
        .padding(Layout.padding)
        .accessibilityElement(children: .contain)
    }
}

private extension PointOfSaleCardPresentPaymentFoundMultipleReadersView {
    @ViewBuilder func readerRow(readerID: String) -> some View {
        HStack {
            Text(readerID)
                .font(.posBodyRegular)
            Spacer()
            Button(Localization.connect) {
                connect(readerID)
            }
            .buttonStyle(TextButtonStyle())
        }
    }

    @ViewBuilder func scanningText() -> some View {
        HStack(spacing: Layout.horizontalSpacing) {
            ActivityIndicator(isAnimating: .constant(true), style: .medium)
            Text(Localization.scanningLabel)
                .font(.posBodyRegular)
            Spacer()
        }
    }
}

private extension PointOfSaleCardPresentPaymentFoundMultipleReadersView {
    enum Localization {
        static let headline = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.foundMultipleReaders.headline",
            value: "Several readers found",
            comment: "Title of a modal presenting a list of readers to choose from."
        )

        static let connect = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.foundMultipleReaders.connect.button.title",
            value: "Connect",
            comment: "Button in a cell to allow the user to connect to that reader for that cell"
        )

        static let scanningLabel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.foundMultipleReaders.scanning.label",
            value: "Scanning for readers",
            comment: "Label for a cell informing the user that reader scanning is ongoing."
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.foundMultipleReaders.cancel.button.title",
            value: "Cancel",
            comment: "Button to allow the user to close the modal without connecting."
        )
    }
}

private extension PointOfSaleCardPresentPaymentFoundMultipleReadersView {
    enum Layout {
        static let padding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let headerPadding: EdgeInsets = .init(top: 20, leading: 4, bottom: 20, trailing: 4)
        static let buttonPadding: EdgeInsets = .init(top: 16, leading: 0, bottom: 16, trailing: 0)
        static let horizontalSpacing: CGFloat = 16
    }
}

#Preview {
    PointOfSaleCardPresentPaymentFoundMultipleReadersView(viewModel: .init(readerIDs: ["Reader 1", "Reader 2"],
                                                                           selectionHandler: { _ in }))
}
