import SwiftUI
import Foundation

struct CustomAmountRowView: View {
    let viewModel: CustomAmountRowViewModel

    var body: some View {
        HStack {
            Text(viewModel.name)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
