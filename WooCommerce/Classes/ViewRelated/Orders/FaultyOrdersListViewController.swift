import SwiftUI
import Foundation
import Networking


final class FaultyOrdersListViewController: UIHostingController<FaultyOrderList> {

    convenience init(faulties: [Faulty<FaultyOrder>]) {
        self.init(rootView: FaultyOrderList(faulties: faulties))
    }

    override init(rootView: FaultyOrderList) {
        super.init(rootView: rootView)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct FaultyOrderList: View {

    let faulties: [Faulty<FaultyOrder>]

    var body: some View {
        List(faulties) { faulty in
            VStack(alignment: .leading, spacing: 8) {
                if let date = faulty.element.date {
                    Text(DateFormatter.mediumLengthLocalizedDateFormatter.string(from: date))
                        .foregroundColor(Color(.textSubtle))
                        .captionStyle()
                }

                HStack {
                    Text("#\(faulty.element.number) \(faulty.element.billingAddress?.firstName ?? "Guest")")
                        .bodyStyle()
                    Spacer()
                    Text(faulty.element.currency + faulty.element.total)
                        .bodyStyle()
                }


                Text(faulty.element.status.description)
                    .captionStyle()
                    .padding(4)
                    .foregroundColor(Color.black)
                    .background(Color(uiColor: backgroundColor(for: faulty.element.status)))
                    .cornerRadius(4)

                Text("Unable to determine: \(faulty.error.context.codingPath.last?.stringValue ?? "")\n\(faulty.error.debugDescription)")
                    .foregroundColor(Color(.textSubtle))
                    .captionStyle()

            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("Problematic Orders")
    }

    private func backgroundColor(for statusEnum: OrderStatusEnum) -> UIColor {
        switch statusEnum {
        case .autoDraft, .pending, .cancelled, .refunded, .custom:
            return .gray(.shade5)
        case .onHold:
            return .withColorStudio(.orange, shade: .shade5)
        case .processing:
            return .withColorStudio(.green, shade: .shade5)
        case .failed:
            return .withColorStudio(.red, shade: .shade5)
        case .completed:
            return .withColorStudio(.blue, shade: .shade5)
        }
    }
}

extension Faulty: Identifiable where Element == FaultyOrder {
    public var id: Int64 {
        element.id
    }
}
