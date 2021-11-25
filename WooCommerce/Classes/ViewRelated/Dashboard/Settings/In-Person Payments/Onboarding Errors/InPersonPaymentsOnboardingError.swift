import SwiftUI

struct InPersonPaymentsOnboardingError: View {
    private let title: String
    private let image: UIImage
    private let message: String

    public init(title: String, message: String, image: UIImage) {
        self.title = title
        self.message = message
        self.image = image
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .center) {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 32)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180.0)
                    .padding(.bottom, 32)
                Text(message)
                    .font(.callout)
                    .padding(.bottom, 24)
                InPersonPaymentsSupportLink()
            }
                .multilineTextAlignment(.center)

            Spacer()

            InPersonPaymentsLearnMore()
        }.padding()
    }
}