import Foundation
import SwiftUI

struct SupportForm: View {

    @State private var favoriteColor = 0
    var body: some View {
        VStack(spacing: 16) {

            VStack(alignment: .leading, spacing: 8) {
                Text("I need help with")
                Picker("I need help with", selection: $favoriteColor) {
                    Text("Payments").tag(0)
                    Text("Mobile App").tag(1)
                    Text("Other").tag(2)
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Subject")
                TextField("", text: .constant(""))
                    .titleStyle()
                    .border(Color(UIColor.gray(.shade5)))
                    .cornerRadius(3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("What are you trying to do")
                TextEditor(text: .constant(""))
                    .border(Color(UIColor.gray(.shade5)))
                    .cornerRadius(3)
            }

            Button {
                // No Op
            } label: {
                Text("Submit Support Request")
            }
            .buttonStyle(PrimaryButtonStyle())

        }
        .padding()
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
    }
}

// MARK: Previews
struct SupportFormProvider: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SupportForm()
        }
    }
}
