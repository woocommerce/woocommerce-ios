import SwiftUI

/// Shown as an accessory view in a row to indicate the row is configurable.
struct ConfigurationIndicator: View {
    var body: some View {
        Image(systemName: Constants.symbolName)
            .font(.system(size: Constants.size))
            .foregroundColor(Color(UIColor.primary))
            .accessibility(hidden: true)
    }
}

// MARK: Constants
private extension ConfigurationIndicator {
    enum Constants {
        static let size: CGFloat = 22.0
        static let symbolName = "gearshape"
    }
}

struct ConfigurationIndicator_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConfigurationIndicator()
                .previewLayout(.sizeThatFits)
        }
    }
}
