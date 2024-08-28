import SwiftUI

struct PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView: View {
    private let viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel) {
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
