import SwiftUI

final class InPersonPaymentsViewController: UIHostingController<InPersonPaymentsView> {
    init() {
        super.init(rootView: InPersonPaymentsView())
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct InPersonPaymentsView: View {
    var body: some View {
        InPersonPaymentsUnavailableView()
            .navigationTitle(Localization.title)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "In-Person Payments",
        comment: "Title for the In-Person Payments settings screen"
    )

    static let unavailable = NSLocalizedString(
        "In-Person Payments is currently unavailable",
        comment: "Title for the error screen when In-Person Payments is unavailable"
    )

    static let acceptCash = NSLocalizedString(
        "You can still accept in-person cash payments by enabling the “Cash on Delivery” payment method on your store.",
        comment: "Generic error message when In-Person Payments is unavailable"
    )
}

struct InPersonPaymentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InPersonPaymentsView()
        }
    }
}
