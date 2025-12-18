import SwiftUI

struct CreateMarketingEventView: View {
    @ObservedObject var viewModel: MarketingToolsViewModel
    @Binding var isPresented: Bool

    @State private var eventName: String = ""
    @State private var eventDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Event Name", text: $eventName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Event Details")
                }

                Section {
                    DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                } header: {
                    Text("When")
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(eventName.isEmpty)
                }
            }
        }
    }

    private func saveEvent() {
        viewModel.createEvent(name: eventName, date: eventDate)
        isPresented = false
    }
}
