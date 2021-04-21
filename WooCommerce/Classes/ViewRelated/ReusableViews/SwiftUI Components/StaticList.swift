import SwiftUI

struct StaticList<Data, Content, FooterContent>: View where Data: RandomAccessCollection, Content: View, FooterContent: View, Data.Element: Identifiable {
    let data: Data
    let rowContent: (Data.Element) -> Content
    let footerContent: (() -> FooterContent)?

    init(_ data: Data, rowContent: @escaping (Data.Element) -> Content, footer footerContent: (() -> FooterContent)? = nil) {
        self.data = data
        self.rowContent = rowContent
        self.footerContent = footerContent
    }

    var body: some View {
        ScrollView {
            VStack {
                ForEach(data) { item in
                    rowContent(item)
                        .fixedSize(horizontal: false, vertical: true) // Forces view to recalculate it's height
                }
                footerContent.map { $0() }
                    .fixedSize(horizontal: false, vertical: true) // Forces view to recalculate it's height
            }
        }
        .background(Color(.listBackground))
    }
}

#if DEBUG

struct StaticList_PreviewItem: Identifiable {
    let id = UUID()
    let title: String
}

struct StaticList_Previews: PreviewProvider {
    static var previews: some View {
        let data = ["One", "Two", "Three"].map { StaticList_PreviewItem(title: $0) }
        StaticList(data) { (item) in
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                Text(item.title)
                    .padding([.leading, .trailing])
                Divider()
            }
        } footer: {
            Text("The footer")
        }
        .environment(\.colorScheme, .light)
    }
}

#endif
