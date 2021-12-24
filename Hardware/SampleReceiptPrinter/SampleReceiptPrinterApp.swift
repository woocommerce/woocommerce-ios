import SwiftUI

@main
struct SampleReceiptPrinterApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ReceiptSettingsView()
                    .navigationTitle("Sample Receipt Printer")
            }
        }
    }
}
