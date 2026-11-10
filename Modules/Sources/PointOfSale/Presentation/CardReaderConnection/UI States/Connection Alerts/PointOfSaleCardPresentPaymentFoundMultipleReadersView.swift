import SwiftUI

/// Displays a list of card readers that are found, with a CTA to connect to a reader and a CTA to cancel reader search.
struct PointOfSaleCardPresentPaymentFoundMultipleReadersView: View {
    @Environment(\.posMetrics) private var metrics
    private let readerIDs: [String]
    private let connect: (String) -> Void
    private let cancelSearch: () -> Void
    @AccessibilityFocusState private var isTitleFocused: Bool

    init(viewModel: PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel) {
        self.readerIDs = viewModel.readerIDs
        self.connect = viewModel.connect
        self.cancelSearch = viewModel.cancelSearch
    }

    var body: some View {
        VStack {
            Text(Localization.headline)
                .font(.posHeadingBold)
                .padding(headerPadding)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isTitleFocused)

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
            .padding(buttonPadding)
        }
        .padding(contentPadding)
        .accessibilityElement(children: .contain)
        .onAppear {
            isTitleFocused = true
        }
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
        .padding(.vertical, metrics.padding.xSmall)
    }

    @ViewBuilder func scanningText() -> some View {
        HStack(spacing: metrics.spacing.medium) {
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
    var contentPadding: EdgeInsets {
        .init(top: metrics.padding.none, leading: metrics.padding.medium, bottom: metrics.padding.none, trailing: metrics.padding.medium)
    }

    var headerPadding: EdgeInsets {
        .init(top: metrics.padding.medium, leading: metrics.padding.xSmall, bottom: metrics.padding.medium, trailing: metrics.padding.xSmall)
    }

    var buttonPadding: EdgeInsets {
        .init(top: metrics.padding.medium, leading: metrics.padding.none, bottom: metrics.padding.medium, trailing: metrics.padding.none)
    }
}

#Preview {
    return PointOfSaleCardPresentPaymentFoundMultipleReadersView(
        viewModel: .init(readerIDs: ["Reader 1", "Reader 2"],
                         selectionHandler: { _ in })
    )
}
