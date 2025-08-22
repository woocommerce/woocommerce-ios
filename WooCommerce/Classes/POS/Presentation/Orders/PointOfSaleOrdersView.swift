import SwiftUI
import UIKit

@available(iOS 17.0, *)
struct PointOfSaleOrdersView: View {
    @Binding var isPresented: Bool
    @State private var selectedOrderID: String? = "order1"
    @State private var listWidth: CGFloat = Constants.defaultListWidth

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            PointOfSaleOrdersListView(selectedOrderID: $selectedOrderID) {
                isPresented = false
            }
            .navigationSplitViewColumnWidth(ideal: listWidth)
        } detail: {
            if let selectedOrderID = selectedOrderID {
                PointOfSaleOrderDetailsView(
                    orderID: selectedOrderID,
                    onBack: {
                        $selectedOrderID.wrappedValue = nil
                    }
                )
            } else {
                VStack {
                    Text("Select an order to view details")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.posSurface)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(Color.posSurface)
        .navigationBarBackButtonHidden(true)
        .measureWidth { totalWidth in
            // Calculate list width as 35% of total width (matching CartView proportion)
            listWidth = totalWidth * Constants.listWidthRatio
        }
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleOrdersView {
    enum Constants {
        // List width ratio - list takes 35% (matching CartView), detail takes 65% (matching ItemListView)
        static let listWidthRatio: CGFloat = 0.35
        static let defaultListWidth: CGFloat = 400
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Orders View") {
    PointOfSaleOrdersView(isPresented: .constant(true))
}
#endif
