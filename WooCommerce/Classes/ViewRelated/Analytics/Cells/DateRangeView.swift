import SwiftUI

struct DateRangeView: View {
    var body: some View {
        VStack {
            Divider()
            Button {
                // Open Date Range Sheet
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 12, content: {
                        Text("Today (Sep 10, 2020)")
                            .font(.system(size: 17))
                            .foregroundColor(Color(UIColor.text))
                        Text("vs Previous Period (Sep 9, 2020)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(UIColor.text))
                    })
                    Spacer()
                    Image(systemName: "calendar")
                        .renderingMode(.template)
                        .foregroundColor(Color(UIColor.accent))
                }
                .padding(EdgeInsets(top: 18, leading: 16, bottom: 13, trailing: 16))
            }
            Divider()
        }
        .background(Color(.listForeground))
    }
}

struct DateRangeView_Previews: PreviewProvider {
    static var previews: some View {
        DateRangeView().previewLayout(.fixed(width: 375, height: 83))
    }
}
