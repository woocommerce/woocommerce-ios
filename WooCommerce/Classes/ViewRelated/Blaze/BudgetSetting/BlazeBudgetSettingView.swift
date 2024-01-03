import SwiftUI

/// View to set budget for a new Blaze campaign
struct BlazeBudgetSettingView: View {

    @Binding var isPresented: Bool

    @State private var amount: Double = 0

    var body: some View {
        VStack(spacing: Layout.sectionSpacing) {
            // Cancel button
            HStack {
                Button(Localization.cancel) {
                    isPresented.toggle()
                }
                Spacer()
            }

            ScrollableVStack(spacing: Layout.sectionSpacing) {
                VStack(spacing: Layout.sectionContentSpacing) {
                    Text("Set your budget")
                        .bold()
                        .largeTitleStyle()

                    Text("How much would you like to spend on your product promotion campaign?")
                        .multilineTextAlignment(.center)
                        .subheadlineStyle()
                }

                VStack {
                    Text("$35")
                        .bold()
                        .largeTitleStyle()

                    Text("for 7 days")
                        .foregroundColor(Color.secondary)
                        .bold()
                        .largeTitleStyle()

                    Text("Total spend $1055")
                        .subheadlineStyle()
                }

                VStack {
                    Text("$5 daily")

                    Slider(value: $amount) {
                        Text("")
                    } minimumValueLabel: {
                        Text("")
                    } maximumValueLabel: {
                        Text("")
                    }

                    Text("Estimated people reached per day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    + Text(" ")
                    + Text(Image(systemName: "info.circle"))
                        .font(.subheadline)

                    Text("2,588 - 3,458")
                        .bold()
                        .font(.subheadline)
                }
            }
        }
        .padding(Layout.contentPadding)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: Layout.sectionContentSpacing) {
                Divider()

                Text("Duration")
                    .secondaryBodyStyle()
                    .padding(.horizontal, Layout.contentPadding)
                    .padding(.top, Layout.sectionContentSpacing)

                HStack {
                    Text("Dec 13 - Dec 19, 2023")
                        .bold()
                        .bodyStyle()
                    Text("·")
                    Text("Edit")
                        .bodyStyle()
                }
                .padding(.horizontal, Layout.contentPadding)

                Button("Update") {
                    // TODO: show duration sheet
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding([.horizontal, .bottom], Layout.contentPadding)
                .padding(.top, Layout.sectionContentSpacing)
            }
            .background(Color(.systemBackground))
        }
    }
}

private extension BlazeBudgetSettingView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let sectionContentSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 32
    }

    enum Localization {
        static let cancel = NSLocalizedString(
            "blazeBudgetSettingView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the Blaze budget setting screen"
        )
    }
}

struct BlazeBudgetSettingView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeBudgetSettingView(isPresented: .constant(true))
    }
}
