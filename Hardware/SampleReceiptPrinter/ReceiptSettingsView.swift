import SwiftUI

struct ReceiptSettingsView: View {
    @State var items =  1
    let range = 1...50

    var body: some View {
        Form {
            Section {
                Stepper(value: $items, in: range) {
                    Text("Receipt Items: \(items)")
                }
            }
            Button("Print") {
                ServiceLocator.printerService.printReceipt(content: .sampleReceipt(items: items))
            }
            Button("Email") {
                // To be implemented in the future
                print("Email tapped")
            }
            Button("Preview") {
                // To be implemented in the future
                print("Preview tapped")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptSettingsView()
    }
}
