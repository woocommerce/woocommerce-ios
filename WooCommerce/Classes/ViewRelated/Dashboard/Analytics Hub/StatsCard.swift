import SwiftUI

/// Resuable report card made for the Analytics Hub.
///
struct AnalyticsReportCard: View {

    var body: some View {
        VStack(alignment: .leading) {

            Text("Title")
                .foregroundColor(Color(.text))
                .footnoteStyle()

            HStack {
                VStack(alignment: .leading) {

                    Text("Left Subtitle")
                        .font(.callout)
                        .foregroundColor(Color(.textSubtle))

                    Text("Left Value")
                        .titleStyle()

                    Text("Left Percentage")
                        .font(.caption)
                        .foregroundColor(Color(.textInverted))
                        .padding(8)
                        .background(Color(.systemGreen))

                }

                VStack(alignment: .leading) {

                    Text("Right Subtitle")
                        .font(.callout)
                        .foregroundColor(Color(.textSubtle))

                    Text("Right Value")
                        .titleStyle()

                    Text("Right Percentage")
                        .font(.caption)
                        .foregroundColor(Color(.textInverted))
                        .padding(8)
                        .background(Color(.systemGreen))
                }
            }
        }
    }
}

// MARK: Previews
struct Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsReportCard()
            .previewLayout(.sizeThatFits)
    }
}
