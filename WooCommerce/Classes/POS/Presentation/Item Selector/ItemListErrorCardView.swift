import SwiftUI

struct ItemListErrorCardView: View {
    let errorState: PointOfSaleErrorState
    let buttonAction: () -> Void
    var body: some View {
        HStack {
            POSErrorExclamationMark()
            VStack {
                Text(errorState.title)
                Text(errorState.subtitle)
            }
            Button {
                buttonAction()
            } label: {
                Text(errorState.buttonText)
            }
        }
    }
}

#Preview {
    ItemListErrorCardView(
        errorState: .errorOnLoadingVariationsNextPage(),
        buttonAction: {}
    )
}
