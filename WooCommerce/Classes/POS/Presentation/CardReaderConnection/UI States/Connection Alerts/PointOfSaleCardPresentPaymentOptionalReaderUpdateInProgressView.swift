import SwiftUI

struct PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView: View {
    private let viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .accessibilityAddTraits(.isHeader)

            viewModel.image
                .accessibilityHidden(true)

            Text(viewModel.progressTitle)
                .font(POSFontStyle.posBodyRegular)
            Text(viewModel.progressSubtitle)
                .font(POSFontStyle.posBodyRegular)

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

struct PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressPreviewView: View {
    @State var showsSheet = false

    var body: some View {
        VStack {
            Button("Open view") {
                showsSheet = true
            }
        }
        .sheet(isPresented: $showsSheet) {
            PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView(viewModel: .init(
                progress: 0.6, cancel: nil
            ))
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressPreviewView()
}

#endif
