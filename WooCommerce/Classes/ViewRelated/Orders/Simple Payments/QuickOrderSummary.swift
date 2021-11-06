import SwiftUI

/// View to summarize the quick order to be created
///
struct QuickOrderSummary: View {
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 10) {

                    HStack {
                        Rectangle()
                            .fill()
                            .foregroundColor(.gray)
                            .frame(width: 48, height: 48)

                        Text("Custom Amount")

                        Spacer()

                        Text("$40.00")
                    }
                    .background(Color.white)


                    TitleAndTextFieldRow(title: "Email", placeholder: "Enter Email", text: .constant(""))
                        .background(Color.white)

                    VStack(alignment: .leading) {
                        Text("Payment")

                        TitleAndValueRow(title: "Subtotal", value: .content("$40.0"), selectable: false) {}

                        TitleAndToggleRow(title: "Charge Taxes", isOn: .constant(false))

                        TitleAndValueRow(title: "Subtotal", value: .content("$40.0"), selectable: false) {}
                    }
                    .background(Color.white)

                    VStack(alignment: .leading) {
                        Text("Order Note")

                        Button(action: {
                            print("Tapped add note")
                        }, label: {
                            HStack {
                                Rectangle()
                                    .fill()
                                    .frame(width: 24, height: 24)

                                Text("Add Note")

                                Spacer()
                            }
                            .foregroundColor(Color(.accent))
                        })
                        .frame(maxWidth: .infinity)


                    }
                    .background(Color.white)

                }
                .background(Color(.listBackground))
            }

            VStack {
                Divider()

                Button("Take Payment ($40.0)", action: {

                })
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

// MARK: Previews

struct QuickOrderSummary_Preview: PreviewProvider {
    static var previews: some View {
        QuickOrderSummary()
            .previewDevice(PreviewDevice(rawValue: "iPhone 12"))
            .previewDisplayName("iPhone 12")
    }
}
