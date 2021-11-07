import SwiftUI

/// View to summarize the quick order to be created
///
struct QuickOrderSummary: View {
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {

                    Group {

                        Divider()

                        HStack {
                            Rectangle()
                                .fill()
                                .foregroundColor(.gray)
                                .frame(width: 48, height: 48)

                            Text("Custom Amount")

                            Spacer()

                            Text("$40.00")
                        }
                        .padding()
                        .background(Color.white)

                        Divider()
                        Spacer(minLength: 16)
                    }

                    Group {
                        Divider()
                        TitleAndTextFieldRow(title: "Email", placeholder: "Enter Email", text: .constant(""))
                            .background(Color.white)
                        Divider()
                        Spacer(minLength: 16)
                    }

                    Group {
                        Divider()
                        VStack(alignment: .leading) {

                            Text("Payment")
                                .padding([.horizontal, .top])

                            TitleAndValueRow(title: "Subtotal", value: .content("$40.0"), selectable: false) {}

                            TitleAndToggleRow(title: "Charge Taxes", isOn: .constant(false))
                                .padding([.leading, .trailing])

                            TitleAndValueRow(title: "Subtotal", value: .content("$40.0"), selectable: false) {}
                        }
                        .background(Color.white)

                        Divider()
                        Spacer(minLength: 16)
                    }

                    Group {
                        Divider()

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
                        .padding()
                        .background(Color.white)

                        Divider()
                    }

                }
            }

            VStack {
                Divider()

                Button("Take Payment ($40.0)", action: {
                    print("Take payment pressed")
                })
                .buttonStyle(PrimaryButtonStyle())
                .padding()

            }
        }
        .background(Color(.listBackground))
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
