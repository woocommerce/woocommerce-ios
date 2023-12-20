import SwiftUI

struct ExpandableBottomSheet<AlwaysVisibleContent, ExpandableContent>: View where AlwaysVisibleContent: View, ExpandableContent: View {
    @State private var isExpanded: Bool = false
    @State private var expandingContentSize: CGSize = .zero
    @State private var fixedContentSize: CGSize = .zero
    @State private var chevronSize: CGSize = .zero
    @State private var panelHeight: CGFloat = 120 // needs to be non-zero so views are initially drawn
    @State private var revealContentDuringDrag: Bool = false
    @GestureState private var isDragging: Bool = false

    @ViewBuilder private var alwaysVisibleContent: () -> AlwaysVisibleContent

    @ViewBuilder private var expandableContent: () -> ExpandableContent

    public init(@ViewBuilder alwaysVisibleContent: @escaping () -> AlwaysVisibleContent,
                @ViewBuilder expandableContent: @escaping () -> ExpandableContent) {
        self.alwaysVisibleContent = alwaysVisibleContent
        self.expandableContent = expandableContent
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chevron button to control view expansion
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: "chevron.compact.up")
                    .font(.system(size: Layout.chevronSize))
                    .accessibilityLabel(isExpanded ? Localization.collapseChevronAccessibilityLabel :
                                            Localization.expandChevronAccessibilityLabel)
                    // The following flips the chevron
                    .scaleEffect(isExpanded ? CGSize(width: 1.0, height: -1.0) :
                                    CGSize(width: 1.0, height: 1.0),
                                 anchor: .center)
                    .animation(.easeIn(duration: 0.15), value: isExpanded)
                    .foregroundColor(Color(uiColor: .primary))
            }
            .padding(Layout.chevronPadding)
            .trackSize(size: $chevronSize)

            Spacer()

            // Content that will expand/collapse
            VStack {
                if isExpanded || revealContentDuringDrag {
                    expandableContent()
                        .transition(.move(edge: .bottom))
                }
            }
            .frame(maxWidth: .infinity)
            .trackSize(size: $expandingContentSize)
            .clipped()

            // Always visible content
            alwaysVisibleContent()
                .trackSize(size: $fixedContentSize)
        }
        .background(GeometryReader { geometryProxy in
            Color.clear
                .onChange(of: geometryProxy.size.height,
                          perform: { newValue in
                    if !isDragging {
                        DispatchQueue.main.async {
                            withAnimation {
                                panelHeight = calculateHeight()
                            }
                        }
                    }
                })
        })
        .onChange(of: isExpanded, perform: { _ in
            DispatchQueue.main.async {
                withAnimation {
                    panelHeight = calculateHeight()
                }
            }
        })
        .background(Color(.listForeground(modal: true)))
        .frame(maxWidth: .infinity, maxHeight: panelHeight, alignment: .bottom)
        .cornerRadius(Layout.sheetCornerRadius)
        .shadow(radius: Layout.shadowRadius)
        .mask(Rectangle().padding(.top, Layout.shadowRadius * -2)) // hide bottom shadow
        .padding([.top], -Layout.shadowRadius) // ensure shadow overlays views "underneath" it
        .gesture(
            DragGesture()
                .updating($isDragging) { value, state, _ in
                    state = value.translation.height < 0
                }
                .onChanged { value in
                    withAnimation {
                        let dragAmount = value.translation.height
                        revealContentDuringDrag = dragAmount < 0
                        panelHeight = calculateHeight(offsetBy: dragAmount)
                    }
                }
                .onEnded { gesture in
                    withAnimation {
                        let dragAmount = gesture.predictedEndTranslation.height as CGFloat
                        let threshold: CGFloat = expandingContentSize.height / 4

                        if dragAmount > threshold && isExpanded {
                            isExpanded = false
                        } else if dragAmount < -threshold && !isExpanded {
                            isExpanded = true
                        }
                        revealContentDuringDrag = false
                    }
                }
        )
        .edgesIgnoringSafeArea(.all)
    }

    private func calculateHeight(offsetBy dragAmount: CGFloat = 0) -> CGFloat {
        let collapsedHeight = fixedContentSize.height + chevronSize.height + Layout.chevronPadding
        let fullHeight = collapsedHeight + expandingContentSize.height
        let currentHeight = isExpanded ? fullHeight : collapsedHeight
        let dragAdjustedHeight = currentHeight - dragAmount

        // Prevent the view from shrinking below the minHeight when dragging down.
        return max(collapsedHeight, dragAdjustedHeight)
    }
}

fileprivate enum Layout {
    static let chevronSize: CGFloat = 30
    static let chevronPadding: CGFloat = 8
    static let sheetCornerRadius: CGFloat = 10
    static let shadowRadius: CGFloat = 5
}

fileprivate enum Localization {
    static let expandChevronAccessibilityLabel = NSLocalizedString(
        "expandableBottomSheet.chevron.expand",
        value: "Show details",
        comment: "Accessibility label to expand an expandable bottom sheet")

    static let collapseChevronAccessibilityLabel = NSLocalizedString(
        "expandableBottomSheet.chevron.collapse",
        value: "Hide details",
        comment: "Accessibility label to collapse an expandable bottom sheet")
}

struct ExpandableBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        ExpandableBottomSheet {
            Text("Always visible")
        } expandableContent: {
            Text("Can be hidden")
        }

    }
}

struct SizeTracker: ViewModifier {
    @Binding var size: CGSize

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        self.size = proxy.size
                    }
                    .onChange(of: proxy.size) { newSize in
                        self.size = newSize
                    }
            })
    }
}

extension View {
    func trackSize(size: Binding<CGSize>) -> some View {
        modifier(SizeTracker(size: size))
    }
}
