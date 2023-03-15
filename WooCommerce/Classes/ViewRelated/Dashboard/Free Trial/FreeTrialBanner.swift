import SwiftUI

/// Free Trial Banner. To be used inside the Dashboard.
///
struct FreeTrialBanner: View {

    var body: some View {
        HStack {
            Image(uiImage: .infoOutlineImage)

            HStack(spacing: 6) {
                Text("Your trial has ended.")
                    .bodyStyle()

                Text("Upgrade Now")
                    .underline(true)
                    .linkStyle()
                    .onTapGesture {
                        print("Upgrade Now Pressed")
                    }
            }
        }
        .padding()
        .background(Color(.wooCommercePurple(.shade5)))
    }
}

struct FreeTrial_Preview: PreviewProvider {
    static var previews: some View {
        FreeTrialBanner()
            .previewLayout(.sizeThatFits)
    }
}
