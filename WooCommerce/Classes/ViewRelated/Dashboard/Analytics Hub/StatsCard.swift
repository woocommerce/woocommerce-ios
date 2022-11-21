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
                        .calloutStyle()

                    Text("Left Value")
                        .titleStyle()

                    Text("Left Percentage")
                        .foregroundColor(Color(.textInverted))
                        .captionStyle()
                        .padding(8)
                        .background(Color(.systemGreen))

                }

                VStack(alignment: .leading) {

                    Text("Right Subtitle")
                        .calloutStyle()

                    Text("Right Value")
                        .titleStyle()

                    Text("Right Percentage")
                        .foregroundColor(Color(.textInverted))
                        .captionStyle()
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
