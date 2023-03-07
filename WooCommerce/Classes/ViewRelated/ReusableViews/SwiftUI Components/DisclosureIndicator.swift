import SwiftUI

struct DisclosureIndicator: View {
    var body: some View {
        Image(systemName: Constants.chevronSymbolName)
            .font(.system(size: Constants.chevronSize, weight: .bold))
            .foregroundColor(Color(UIColor.systemGray3))
            .accessibility(hidden: true)
    }
}

// MARK: Constants
private extension DisclosureIndicator {
    enum Constants {
        static let chevronSize: CGFloat = 14.0
        static let chevronSymbolName = "chevron.forward"
    }
}

struct DisclosureIndicator_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DisclosureIndicator()
                .previewLayout(.sizeThatFits)
        }
    }
}
