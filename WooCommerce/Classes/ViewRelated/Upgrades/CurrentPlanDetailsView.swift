import SwiftUI

struct CurrentPlanDetailsView: View {
    @State var expirationDate: String?
    @State var daysLeft: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            Text("You're in a free trial")
                .font(.title2.bold())
            if let expirationDate = expirationDate, let daysLeft = daysLeft {
                Text("Your free trial will end in \(daysLeft) days. Upgrade to a plan by \(expirationDate) to unlock new features and start selling.")
                    .font(.footnote)
            } else {
                Text("Your free trial will end soon. Upgrade to unlock new features and start selling.")
                    .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing])
        .padding(.vertical, Layout.smallPadding)
    }
}

private extension CurrentPlanDetailsView {
    struct Layout {
        static let contentSpacing: CGFloat = 8
        static let smallPadding: CGFloat = 8
    }
}
