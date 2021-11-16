import SwiftUI

struct NewOrder: View {
    var body: some View {
        ScrollView {
            EmptyView()
        }
        .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
    }
}

struct NewOrder_Previews: PreviewProvider {
    static var previews: some View {
        NewOrder()
    }
}
