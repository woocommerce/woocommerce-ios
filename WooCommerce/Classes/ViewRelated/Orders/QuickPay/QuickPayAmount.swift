import Foundation
import SwiftUI

/// View that receives an arbitrary amount for creating a quick pay order.
///
struct QuickPayAmount: View {
    var body: some View {
        Text("Holi")
    }
}

private struct QuickPayAmount_Preview: PreviewProvider {
    static var previews: some View {
        QuickPayAmount()
            .environment(\.colorScheme, .light)
    }
}
