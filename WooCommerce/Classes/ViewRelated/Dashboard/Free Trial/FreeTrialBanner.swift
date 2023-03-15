import SwiftUI

/// Free Trial Banner. To be used inside the Dashboard.
///
struct FreeTrialBanner: View {

    var body: some View {
        Text("Free Trial")
    }
}

struct FreeTrial_Preview: PreviewProvider {
    static var previews: some View {
        FreeTrialBanner()
            .previewLayout(.sizeThatFits)
    }
}
