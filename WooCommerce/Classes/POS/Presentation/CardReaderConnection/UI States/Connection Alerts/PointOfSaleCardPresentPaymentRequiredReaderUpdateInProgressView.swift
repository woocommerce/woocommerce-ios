import SwiftUI

struct PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressView: View {
    private let viewModel: PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
            Spacer()
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                viewModel.image
                    .accessibilityHidden(true)

                VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                    Text(viewModel.title)
                        .font(POSFontStyle.posTitleEmphasized)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    Text(viewModel.progressTitle)
                        .font(POSFontStyle.posBodyRegular)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(viewModel.progressSubtitle)
                        .font(POSFontStyle.posBodyRegular)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            Button(viewModel.cancelButtonTitle,
                   action: {
                if let cancelReaderUpdate = viewModel.cancelReaderUpdate {
                    cancelReaderUpdate()
                }
            })
            .buttonStyle(POSSecondaryButtonStyle())
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
