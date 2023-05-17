import SwiftUI
import WooFoundation

struct ScanToPayView: View {
    let viewModel: ScanToPayViewModel
    let onSuccess: (() -> Void)

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
            VStack {
                VStack(alignment: .center, spacing: 20) {
                    if let qrCodeImage = viewModel.generateQRCodeImage() {
                        Text(Localization.title)
                            .foregroundColor(.white)
                        Image(uiImage: qrCodeImage)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 270, height: 300)
                        DoneButton() {
                            onSuccess()
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Text(Localization.errorMessage)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        DoneButton() {
                            dismiss()
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(.gray(.shade70)))
                .cornerRadius(8)

            }
            .padding(50)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private struct DoneButton: View {
        let onButtonTapped: (() -> Void)
        var body: some View {
            Button(Localization.doneButtontitle) {
                onButtonTapped()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

extension ScanToPayView {
    enum Localization {
        static let title = NSLocalizedString("Scan QR and follow instructions", comment: "Title text on the Scan to Pay screen")
        static let doneButtontitle = NSLocalizedString("Done", comment: "Button title to close the Scan to Pay screen")
        static let errorMessage = NSLocalizedString("Error generating QR Code. Please try again later",
                                                    comment: "Error message in the Scan to Pay screen when the code cannot be generated.")
    }
}
