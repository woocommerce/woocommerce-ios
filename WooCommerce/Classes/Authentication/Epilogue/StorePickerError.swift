import SwiftUI

/// Hosting controller wrapper for `StorePickerError`
///
final class StorePickerErrorHostingController: UIHostingController<StorePickerError> {
    init() {
        super.init(rootView: StorePickerError())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/// Generic Store Picker error view that allows the user to contact support.
///
struct StorePickerError: View {
    var body: some View {
        VStack(alignment: .center) {
            // Title
            Text("We couldn't load your site")
                .headlineStyle()

            // Main image
            Image(uiImage: .errorImage)

            // Body text
            Text("Please try again or reach out to us and we'll be happy to assist you!")
                .bodyStyle()

            // Primary Button
            Button("Read our Troubleshooting Tips") {
                print("Troubleshooting Tips tapped")
            }
            .buttonStyle(PrimaryButtonStyle())

            // Secondary button
            Button("Contact Support") {
                print("Contact support tapped")
            }
            .buttonStyle(SecondaryButtonStyle())

            // Dismiss button
            Button("Back to Sites") {
                print("Back to site")
            }
            .buttonStyle(LinkButtonStyle())
        }
        .background(Color(.basicBackground))
        .padding()
    }
}

// MARK: Previews

struct StorePickerError_Preview: PreviewProvider {
    static var previews: some View {
        StorePickerError()
            .previewLayout(.fixed(width: 414, height: 768))
    }
}
