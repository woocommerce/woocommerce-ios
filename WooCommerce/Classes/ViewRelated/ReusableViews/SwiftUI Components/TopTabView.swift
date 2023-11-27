import SwiftUI

struct TopTabItem {
    let name: String
    let view: AnyView
    let onSelected: (() -> Void)?

    init(name: String,
         view: AnyView,
         onSelected: (() -> Void)? = nil) {
        self.name = name
        self.view = view
        self.onSelected = onSelected
    }
}

struct TopTabView: View {
    @State private var selectedTab = 0
    @State private var underlineOffset: CGFloat = 0
    @State private var tabWidths: [CGFloat]
    @GestureState private var dragState: DragState = .inactive

    @Binding var showTabs: Bool

    let tabs: [TopTabItem]

    init(tabs: [TopTabItem],
         showTabs: Binding<Bool> = .constant(true)) {
        self.tabs = tabs
        self._showTabs = showTabs
        _tabWidths = State(initialValue: [CGFloat](repeating: 0, count: tabs.count))
    }

    var body: some View {
        VStack(spacing: 0) {
            if tabs.count > 1 && showTabs {
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollViewProxy in
                        HStack(spacing: Layout.tabPadding * 2) {
                            ForEach(0..<tabs.count, id: \.self) { index in
                                VStack {
                                    Text(tabs[index].name)
                                        .font(.headline)
                                        .foregroundColor(selectedTab == index ? Colors.selected : .primary)
                                        .id(index)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedTab = index
                                                tabs[selectedTab].onSelected?()
                                                underlineOffset = calculateOffset(index: index)
                                                scrollViewProxy.scrollTo(index, anchor: .center)
                                            }
                                        }
                                        .accessibilityAddTraits(.isButton)
                                        .accessibilityAddTraits(selectedTab == index ? [.isSelected, .isHeader] : [])
                                }
                                .padding()
                                .background(GeometryReader { geometry in
                                    Color.clear.onAppear {
                                        if index < tabWidths.count {
                                            tabWidths[index] = geometry.size.width
                                            if index == selectedTab {
                                                underlineOffset = calculateOffset(index: index)
                                            }
                                        }
                                    }
                                })
                            }
                        }
                        .padding(.horizontal, Layout.tabPadding)
                        .overlay(
                            Rectangle()
                                .frame(width: selectedTabUnderlineWidth(),
                                       height: Layout.selectedTabIndicatorHeight)
                                .foregroundColor(Colors.selected)
                                .offset(x: underlineOffset),
                            alignment: .bottomLeading
                        )
                    }
                }
                Divider()
            }

            // Display Content for selected tab
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        tabs[index].view
                            .frame(width: geometry.size.width)
                    }
                }
                .offset(x: self.dragOffset(width: geometry.size.width))
                .animation(.interactiveSpring(), value: dragOffset(width: geometry.size.width))
                .gesture(
                    DragGesture()
                        .updating($dragState) { drag, state, transaction in
                            state = .dragging(translation: drag.translation)
                        }
                        .onEnded { drag in
                            let horizontalAmount = drag.predictedEndTranslation.width as CGFloat
                            let threshold: CGFloat = geometry.size.width / 2
                            let newIndex: Int
                            if horizontalAmount > threshold {
                                newIndex = max(selectedTab - 1, 0)
                            } else if horizontalAmount < -threshold {
                                newIndex = min(selectedTab + 1, tabs.count - 1)
                            } else {
                                newIndex = selectedTab
                            }

                            // Update underlineOffset when the tab changes
                            underlineOffset = calculateOffset(index: newIndex)

                            // Call the onSelected closure if it exists for the new tab
                            tabs[newIndex].onSelected?()

                            // Update the selected tab to the new index
                            withAnimation(.easeOut) {
                                selectedTab = newIndex
                            }
                        }
                )
            }
            .frame(height: 300)
        }
    }

    private func selectedTabUnderlineWidth() -> CGFloat {
        guard let selectedTabWidth = tabWidths[safe: selectedTab] else {
            DDLogError("Out of bounds tab selected at index \(selectedTab)")
            return 0
        }
        return selectedTabWidth + (Layout.tabPadding * 2)
    }

    private func calculateOffset(index: Int) -> CGFloat {
        // Takes all preceeding tab widths, and adds appropriate spacing to each side to get the overall offset
        return tabWidths.prefix(index).reduce(0, +) + CGFloat(index) * (Layout.tabPadding * 2)
    }

    private func onDragEnded(drag: DragGesture.Value) {
        let thresholdPercentage: CGFloat = 0.5 // Threshold to swipe to next tab
        let dragThreshold = thresholdPercentage * UIScreen.main.bounds.width
        if drag.predictedEndTranslation.width > dragThreshold {
            selectedTab = max(selectedTab - 1, 0)
        } else if drag.predictedEndTranslation.width < -dragThreshold {
            selectedTab = min(selectedTab + 1, tabs.count - 1)
        }
    }

    private func dragOffset(width: CGFloat) -> CGFloat {
        if dragState.isActive {
            let offset = -CGFloat(selectedTab) * width + dragState.translation.width
            return offset
        } else {
            return -CGFloat(selectedTab) * width
        }
    }

    enum DragState {
        case inactive
        case dragging(translation: CGSize)

        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }

        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }

    private enum Layout {
        static let tabPadding: CGFloat = 10
        static let selectedTabIndicatorHeight: CGFloat = 2
    }

    private enum Colors {
        static let selected: Color = .withColorStudio(name: .wooCommercePurple, shade: .shade50)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let tabs: [TopTabItem] = [
            TopTabItem(name: "A tab name", view: AnyView(Text("Content for Tab 1")
                .font(.largeTitle)
                .padding())),
            TopTabItem(name: "Tab2", view: AnyView(Text("Content for Tab 2")
                .font(.largeTitle)
                .padding())),
            TopTabItem(name: "More detail", view: AnyView(Text("Content for Tab 3")
                .font(.largeTitle)
                .padding())),
            TopTabItem(name: "A really long tab name", view: AnyView(Text("Content for Tab 4")
                .font(.largeTitle)
                .padding())),
            TopTabItem(name: "Tab", view: AnyView(Text("Content for Tab 5")
                .font(.largeTitle)
                .padding())),
        ]
        TopTabView(tabs: tabs)
            .previewLayout(.sizeThatFits)

        let oneTab: [TopTabItem] = [
            TopTabItem(name: "A tab name", view: AnyView(Text("Content for Tab 1")
                .font(.largeTitle)
                .padding()))
        ]
        TopTabView(tabs: oneTab)
            .previewLayout(.sizeThatFits)
    }
}
