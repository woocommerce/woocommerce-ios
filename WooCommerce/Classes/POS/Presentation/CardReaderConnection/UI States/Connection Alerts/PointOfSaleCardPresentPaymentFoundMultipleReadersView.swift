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
        VStack {
            Text(Localization.headline)
                .font(.posHeadingBold)
                .padding(Layout.headerPadding)
                .accessibilityAddTraits(.isHeader)

            scanningText()

            List(readerIDs, id: \.self) { readerID in
                readerRow(readerID: readerID)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.posSurface)
            }
            .listStyle(.plain)

            Button(action: {
                cancelSearch()
            }) {
                Text(Localization.cancel)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
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
                .font(.posBodyLargeRegular())
            Spacer()
            Button(Localization.connect) {
                connect(readerID)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .extraSmall))
        }
        .padding(.vertical, Layout.rowVerticalPadding)
    }

    @ViewBuilder func scanningText() -> some View {
        HStack(spacing: Layout.horizontalSpacing) {
            Spacer()
            ProgressView()
                .progressViewStyle(POSProgressViewStyle(size: 20, lineWidth: 4))
            Text(Localization.scanningLabel)
                .font(.posBodyLargeRegular())
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
        static let padding: EdgeInsets = .init(top: POSPadding.none,
                                               leading: POSPadding.medium,
                                               bottom: POSPadding.none,
                                               trailing: POSPadding.medium)
        static let headerPadding: EdgeInsets = .init(top: POSPadding.medium,
                                                     leading: POSPadding.xSmall,
                                                     bottom: POSPadding.medium,
                                                     trailing: POSPadding.xSmall)
        static let buttonPadding: EdgeInsets = .init(top: POSPadding.medium,
                                                     leading: POSPadding.none,
                                                     bottom: POSPadding.medium,
                                                     trailing: POSPadding.none)
        static let horizontalSpacing: CGFloat = POSSpacing.medium
        static let rowVerticalPadding: CGFloat = POSPadding.xSmall
    }
}

#Preview {
    return PointOfSaleCardPresentPaymentFoundMultipleReadersView(
        viewModel: .init(readerIDs: ["Reader 1", "Reader 2"],
                         selectionHandler: { _ in })
    )
}
