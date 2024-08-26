import SwiftUI

struct PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressView: View {
    private let viewModel: PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posBodyRegular)
                .accessibilityAddTraits(.isHeader)

            viewModel.image
                .accessibilityHidden(true)

            Text(viewModel.progressTitle)
                .font(POSFontStyle.posDetailLight)
            Text(viewModel.progressSubtitle)
                .font(POSFontStyle.posDetailLight)

            Button(viewModel.cancelButtonTitle,
                   action: {
                if let cancelReaderUpdate = viewModel.cancelReaderUpdate {
                    cancelReaderUpdate()
                }
            })
            .buttonStyle(SecondaryButtonStyle())
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG

struct CardPresentPaymentRequiredReaderUpdateInProgressPreviewView: View {
    @State var showsSheet = false

    var body: some View {
        VStack {
            Button("Open view") {
                showsSheet = true
            }
        }
        .sheet(isPresented: $showsSheet) {
            PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressView(viewModel: .init(
                progress: 0.6, cancel: nil
            ))
        }
    }
}

#Preview {
    CardPresentPaymentRequiredReaderUpdateInProgressPreviewView()
}

#endif
