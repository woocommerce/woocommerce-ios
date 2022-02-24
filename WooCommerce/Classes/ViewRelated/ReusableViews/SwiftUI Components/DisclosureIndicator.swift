import SwiftUI

struct DisclosureIndicator: View {
    /// Keeps track of the current screen scale
    ///
    @ScaledMetric private var scale = 1

    var body: some View {
        Image(uiImage: .chevronImage)
            .resizable()
            .flipsForRightToLeftLayoutDirection(true)
            .frame(width: Constants.chevronSize(scale: scale), height: Constants.chevronSize(scale: scale))
            .foregroundColor(Color(.systemGray))
            .accessibility(hidden: true)
    }
}

// MARK: Constants
private extension DisclosureIndicator {
    enum Constants {
        static func chevronSize(scale: CGFloat) -> CGFloat {
            22 * scale
        }
    }
}

struct DisclosureIndicator_Previews: PreviewProvider {
    static var previews: some View {
        DisclosureIndicator()
            .previewLayout(.sizeThatFits)
    }
}
