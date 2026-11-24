import SwiftUI

struct POSGuidedAccessIllustration: View {
    enum Device: Hashable {
        case pad
        case phone(heightRatio: CGFloat)
    }

    static func size(for device: Device) -> CGSize {
        Layout(device).size
    }

    let slide: POSGuidedAccessGuideSlide
    var device = Device.pad
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var powerTouch = Touch()
    @State private var isPowerHighlighted = false
    @State private var showsSessionExample = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            hardwareButtons
                .opacity(slide == .start ? 1 : 0)
            ZStack(alignment: .topLeading) {
                if slide == .start {
                    POSGuidedAccessPOSScene(layout: layout, showsActiveMessage: showsSessionExample || reduceMotion)
                        .transition(Constants.sceneTransition)
                } else {
                    POSGuidedAccessSettingsScene(layout: layout, showsGuidedAccess: slide == .turnOn).transition(Constants.sceneTransition)
                }
            }
            .frame(width: layout.screen.width, height: layout.screen.height, alignment: .topLeading)
            .background(Color.posSurface)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.extraLarge.value))
            .overlay(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.extraLarge.value).strokeBorder(Color.posOutlineVariant))
            .offset(x: layout.origin.x, y: layout.origin.y)
            TouchIndicator(touch: powerTouch, pressOffset: layout.powerPressOffset)
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
        // The drawing keeps the coordinates of its design frames.
        .environment(\.layoutDirection, .leftToRight)
        // Fixed drawing coordinates do not scale with text; the caption carries Dynamic Type and VoiceOver.
        .dynamicTypeSize(.large)
        .environment(\.posLayoutScale, .regular)
        .accessibilityHidden(true)
        .task(id: AnimationKey(slide: slide, reduceMotion: reduceMotion)) { await playPowerClicks() }
    }

    private var layout: Layout {
        Layout(device)
    }

    private var hardwareButtons: some View {
        let depth = powerTouch.isPressed ? Constants.pressedPowerDepth : Constants.powerDepth
        let color = isPowerHighlighted || reduceMotion ? Color.posPrimary : .posOutlineVariant
        return ZStack(alignment: .topLeading) {
            ForEach(layout.volumeButtons, id: \.self) { y in
                block(2, 21, .posOutlineVariant).at(layout.origin.x - 2, y)
            }
            if layout.isPhone {
                UnevenRoundedRectangle(bottomTrailingRadius: 2, topTrailingRadius: 2)
                    .fill(color)
                    .frame(width: depth, height: Constants.powerLength)
                    .at(layout.origin.x + layout.screen.width, layout.powerTouch.y - Constants.powerLength / 2)
            } else {
                UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2)
                    .fill(color)
                    .frame(width: Constants.powerLength, height: depth)
                    .at(layout.powerTouch.x - Constants.powerLength / 2, layout.origin.y - depth)
            }
        }
    }

    private func playPowerClicks() async {
        powerTouch = Touch()
        isPowerHighlighted = false
        showsSessionExample = false
        guard slide == .start, !reduceMotion else { return }
        while !Task.isCancelled {
            guard await pause(Constants.powerDelay) else { return }
            withAnimation(.easeInOut(duration: 0.3)) { isPowerHighlighted = true }
            guard await $powerTouch.press(at: layout.powerTouch) else { return }
            for _ in 1..<3 {
                withAnimation(.easeOut(duration: 0.1)) { powerTouch.isPressed = false }
                guard await pause(Constants.clickGap) else { return }
                withAnimation(.easeOut(duration: 0.1)) { powerTouch.isPressed = true }
                guard await pause(Constants.clickGap) else { return }
            }
            $powerTouch.lift()
            guard await pause(Constants.activeMessageDelay) else { return }
            withAnimation(.spring(duration: 0.4, bounce: 0.3)) { showsSessionExample = true }
            guard await pause(Constants.activeMessageHold) else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                showsSessionExample = false
                isPowerHighlighted = false
            }
            guard await pause(Constants.powerRestartDelay) else { return }
        }
    }
}

private struct POSGuidedAccessSettingsScene: View {
    let layout: Layout
    let showsGuidedAccess: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Int
    @State private var flowStep: Int
    @State private var isFlowShown: Bool
    @State private var isRewinding = false
    @State private var touch = Touch()

    init(layout: Layout, showsGuidedAccess: Bool) {
        self.layout = layout
        self.showsGuidedAccess = showsGuidedAccess
        // Arriving on the Guided Access slide from the POS one lands on the end of its loop.
        _step = State(initialValue: showsGuidedAccess ? Constants.settingsSteps : 0)
        _flowStep = State(initialValue: showsGuidedAccess ? Constants.flowSteps : 0)
        _isFlowShown = State(initialValue: showsGuidedAccess)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            sidebar
            // A phone pushes the page over the list of settings; a tablet fades it in next to the list.
            accessibilityPage
                .offset(y: shownStep > 1 ? -layout.scrollDistance : 0)
                .frame(width: layout.pageWidth, height: layout.screen.height, alignment: .topLeading)
                .background(Color.posSurface)
                .offset(x: isPageShown ? 0 : layout.pageEntryOffset)
                .opacity(isPageShown || layout.isPhone ? 1 : 0)
                .frame(width: layout.pageWidth, height: layout.screen.height, alignment: .topLeading)
                .clipped()
                .offset(x: layout.pageX)
            if reduceMotion ? showsGuidedAccess : isFlowShown {
                POSGuidedAccessPasscodePages(layout: layout, step: reduceMotion ? Constants.flowSteps : flowStep, pressedKey: pressedKey)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                    .zIndex(1)
            }
            TouchIndicator(touch: touch)
                .zIndex(2)
        }
        .frame(width: layout.screen.width, height: layout.screen.height, alignment: .topLeading)
        .task(id: AnimationKey(slide: showsGuidedAccess ? .turnOn : .openSettings, reduceMotion: reduceMotion)) {
            guard !reduceMotion else { return }
            if showsGuidedAccess {
                await playTurnOn()
            } else {
                await playOpenSettings()
            }
        }
    }

    private var shownStep: Int {
        reduceMotion ? Constants.settingsSteps : step
    }

    private var isPageShown: Bool {
        shownStep > 0 && !isRewinding
    }

    private var pressedKey: Int? {
        touch.isPressed && flowStep > Constants.keypadStep ? Constants.passcodeKeys[flowStep - Constants.keypadStep - 1] : nil
    }

    private func playOpenSettings() async {
        $touch.lift()
        withAnimation(.easeInOut(duration: 0.35)) {
            isFlowShown = false
            isRewinding = false
        }
        while !Task.isCancelled {
            if step < Constants.settingsSteps {
                guard await pause(Constants.startDelay), await $touch.press(at: layout.sidebarTouch) else { return }
                withAnimation(.easeOut(duration: 0.35)) { step = 1 }
                $touch.lift()
                guard await pause(Constants.beat), await $touch.press(at: layout.dragStart) else { return }
                withAnimation(.easeInOut(duration: 0.7)) {
                    step = 2
                    touch.point.y -= layout.scrollDistance
                }
                guard await pause(Constants.dragDuration) else { return }
                $touch.lift()
                guard await pause(Constants.outlineDelay) else { return }
                withAnimation(.easeOut(duration: 0.25)) { step = Constants.settingsSteps }
            }
            guard await pause(Constants.settingsHold) else { return }
            withAnimation(.easeInOut(duration: 0.35)) { isRewinding = true }
            guard await pause(Constants.beat) else { return }
            step = 0
            isRewinding = false
        }
    }

    private func playTurnOn() async {
        $touch.lift()
        withAnimation(.easeInOut(duration: 0.35)) {
            step = Constants.settingsSteps
            isRewinding = false
        }
        while !Task.isCancelled {
            if !isFlowShown {
                flowStep = 0
                guard await pause(Constants.startDelay), await $touch.press(at: layout.guidedAccessTouch) else { return }
                withAnimation(.easeInOut(duration: 0.35)) { isFlowShown = true }
                $touch.lift(hides: false)
                guard await pause(Constants.switchDelay), await $touch.press(at: layout.switchTouch) else { return }
                $touch.lift(hides: false)
                for next in 1..<Constants.passcodePageStep {
                    withAnimation(.snappy(duration: 0.3)) { flowStep = next }
                    guard await pause(Constants.cascadeInterval) else { return }
                }
                guard await pause(Constants.longBeat), await $touch.press(at: layout.passcodeRowTouch) else { return }
                $touch.lift(hides: false)
                withAnimation(.easeInOut(duration: 0.35)) { flowStep = Constants.passcodePageStep }
                guard await pause(Constants.longBeat), await $touch.press(at: layout.setPasscodeTouch) else { return }
                $touch.lift(hides: false)
                withAnimation(.easeOut(duration: 0.25)) { flowStep = Constants.keypadStep }
                guard await pause(Constants.typingDelay) else { return }
                for key in Constants.passcodeKeys {
                    flowStep += 1
                    let origin = layout.keyOrigin(key)
                    let center = CGPoint(x: origin.x + Constants.keySize / 2, y: origin.y + Constants.keySize / 2)
                    guard await $touch.press(at: center, leadIn: Constants.keyLeadIn) else { return }
                    $touch.lift(hides: false)
                }
                $touch.lift()
            }
            guard await pause(Constants.loopHold) else { return }
            withAnimation(.easeInOut(duration: 0.35)) { isFlowShown = false }
            guard await pause(Constants.beat) else { return }
        }
    }

    private var sidebar: some View {
        ZStack(alignment: .topLeading) {
            Color.posSurfaceBright.frame(width: layout.sidebarWidth)
            block(layout.sidebarWidth - 19, 20, Constants.fill).at(11, 17)
            block(layout.sidebarWidth - 9, 19, Constants.fill).at(5, 170).opacity(isPageShown ? 1 : 0)
            ForEach(layout.sidebarRows, id: \.y) { row in
                block(11, 11, .posOutlineVariant, radius: POSCornerRadiusStyle.extraSmall.value).at(11, row.y)
                block(row.width, 8, .posOutlineVariant).at(26, row.y + 1)
            }
            block(11, 11, Constants.settingsBlue, radius: POSCornerRadiusStyle.extraSmall.value).at(11, 174)
            label(Localization.accessibility, size: 10, weight: .bold, width: layout.sidebarWidth - 34).at(26, 169)
        }
    }

    private var accessibilityPage: some View {
        let width = layout.pageWidth
        return ZStack(alignment: .topLeading) {
            card(width: width - 24, height: 86).at(11, 17)
            block(23, 23, Constants.settingsBlue, radius: POSCornerRadiusStyle.medium.value).at(19, 27)
            label(Localization.accessibility, size: 10, weight: .bold, width: width - 40).at(19, 51)
            block(width - 39, 8, .posOutlineVariant).at(19, 74)
            block(width - 54, 8, .posOutlineVariant).at(19, 88)
            listGroup([23, 41, 28, 41], y: 113)
            ForEach(0..<layout.extraGroups, id: \.self) { index in
                listGroup([41, 28, 57, 23], y: 218 + CGFloat(index) * Constants.groupPitch)
            }
            Group {
                label(Localization.general, size: 8, color: .posOnSurfaceVariantHighest, width: width - 24).at(11, 210)
                card(width: width - 24, height: 83).at(11, 228)
                block(11, 11, .posShadow, radius: POSCornerRadiusStyle.extraSmall.value).at(18, 237)
                label(POSSecuritySettingsView.Localization.guidedAccess, size: 9, width: width - 79).at(33, 232)
                block(15, 8, .posOutlineVariant).at(width - 34, 238)
                listRows([57, 28, 41], y: 255)
                RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                    .strokeBorder(Color.posOnSurface)
                    .frame(width: width - 30, height: 17)
                    .opacity(shownStep > 2 ? 1 : 0)
                    .at(14, 234)
                listGroup([41, 23, 57, 28], y: 321)
                listGroup([28, 41, 23, 57], y: 321 + Constants.groupPitch)
            }
            .offset(y: layout.generalShift)
        }
    }

    @ViewBuilder
    private func listGroup(_ widths: [CGFloat], y: CGFloat) -> some View {
        block(40, 8, .posOutlineVariant).at(11, y)
        card(width: layout.pageWidth - 24, height: 83).at(11, y + 12)
        listRows(widths, y: y + 21)
    }

    private func listRows(_ widths: [CGFloat], y: CGFloat) -> some View {
        ForEach(Array(widths.enumerated()), id: \.offset) { index, width in
            let rowY = y + CGFloat(index) * 18
            block(11, 11, .posOutlineVariant, radius: POSCornerRadiusStyle.extraSmall.value).at(18, rowY)
            block(width, 8, .posOutlineVariant).at(33, rowY + 1)
            block(15, 8, .posOutlineVariant).at(layout.pageWidth - 34, rowY + 1)
        }
    }
}

private struct POSGuidedAccessPasscodePages: View {
    let layout: Layout
    let step: Int
    let pressedKey: Int?

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                guidedAccessPage
                if step >= Constants.passcodePageStep {
                    passcodePage
                        .frame(width: width, height: layout.screen.height, alignment: .topLeading)
                        .background(Color.posSurface)
                        .transition(.move(edge: .trailing))
                }
            }
            .frame(width: width, height: layout.screen.height, alignment: .topLeading)
            .background(Color.posSurface)
            .clipped()
            .offset(x: layout.pageX)
            if step >= Constants.keypadStep {
                keypad.transition(.opacity)
            }
        }
        .frame(width: layout.screen.width, height: layout.screen.height, alignment: .topLeading)
    }

    private var width: CGFloat {
        layout.pageWidth
    }

    @ViewBuilder
    private var pageHeader: some View {
        block(16, 16, .posOutlineVariant).at(11, 9)
        block(71, 8, .posOutlineVariant).at((width - 73) / 2, 14)
    }

    private var guidedAccessPage: some View {
        ZStack(alignment: .topLeading) {
            pageHeader
            card(width: width - 24, height: 28).at(11, 38)
            label(POSSecuritySettingsView.Localization.guidedAccess, size: 9, width: width - 64).at(19, 42)
            Capsule()
                .fill(step > 0 ? Color.posSuccess : .posOnSurfaceVariantLowest)
                .frame(width: 15, height: 8)
                .overlay(alignment: step > 0 ? .trailing : .leading) {
                    Circle().fill(Color.posOnPrimary).frame(width: 6, height: 6).frame(width: 8, height: 8)
                }
                .at(width - 34, 48)
            Group {
                block(width - 24, 6, .posOutlineVariant).at(11, 72)
                block(width - 80, 6, .posOutlineVariant).at(11, 82)
            }
            .revealed(step > 1)
            Group {
                card(width: width - 24, height: 28).at(11, 101)
                label(Localization.passcodeSettings, size: 9, width: width - 40).at(19, 105)
            }
            .revealed(step > 2)
            ForEach(Array([50, 93, 84].enumerated()), id: \.offset) { index, barWidth in
                Group {
                    card(width: width - 24, height: 28).at(11, 143 + CGFloat(index) * 39)
                    block(barWidth, 8, .posOutlineVariant).at(19, 153 + CGFloat(index) * 39)
                }
                .revealed(step > 3 + index)
            }
        }
    }

    private var passcodePage: some View {
        ZStack(alignment: .topLeading) {
            pageHeader
            card(width: width - 24, height: 28).at(11, 38)
            label(Localization.setPasscode, size: 9, color: Constants.settingsBlue, width: width - 40).at(19, 42)
            card(width: width - 24, height: 28).at(11, 77)
            block(93, 8, .posOutlineVariant).at(19, 87)
        }
    }

    private var keypad: some View {
        ZStack(alignment: .topLeading) {
            Color.posShadow.opacity(0.7)
            block(Constants.keypadSize.width, Constants.keypadSize.height, .posSurfaceBright, radius: POSCornerRadiusStyle.large.value)
                .at(layout.keypadOrigin.x, layout.keypadOrigin.y)
            ForEach(0..<9) { key in
                block(Constants.keySize, Constants.keySize, key == pressedKey ? .posOnSurfaceVariantLowest : .posOutlineVariant,
                      radius: POSCornerRadiusStyle.medium.value)
                    .at(layout.keyOrigin(key).x, layout.keyOrigin(key).y)
            }
        }
    }
}

private struct POSGuidedAccessPOSScene: View {
    let layout: Layout
    let showsActiveMessage: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            block(48, 16, .posOutline).at(layout.posInset, 14)
            block(48, 16, .posOutlineVariant).at(layout.posInset + 55, 14)
            if layout.isPhone {
                block(16, 16, .posOutlineVariant).at(layout.screen.width - 48, 14)
                block(16, 16, .posOutlineVariant).at(layout.screen.width - 28, 14)
            } else {
                Color.posSurfaceBright.frame(width: 132).offset(x: 243)
                block(16, 16, .posOutlineVariant).at(206, 14)
                block(48, 16, .posOutline).at(255, 14)
            }
            ForEach(0..<layout.posRows, id: \.self) { index in
                ZStack(alignment: .topLeading) {
                    card(width: layout.posRowWidth, height: 47)
                    Constants.fill.frame(width: 52, height: 47)
                    block(75, 10, .posOnSurfaceVariantLowest).at(65, 11)
                    block(50, 8, .posOutlineVariant).at(65, 28)
                }
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
                .at(layout.posInset, 54 + CGFloat(index) * Constants.posRowPitch)
            }
            activeMessage
                .scaleEffect(showsActiveMessage ? 1 : 0.9)
                .opacity(showsActiveMessage ? 1 : 0)
                .at(layout.activeMessageOrigin.x, layout.activeMessageOrigin.y)
        }
    }

    private var activeMessage: some View {
        HStack(spacing: POSMetrics.regular.spacing.xSmall) {
            Image(systemName: "checkmark")
                .font(.posCaptionBold)
                .scaleEffect(9.0 / 14)
                .frame(width: 9, height: 14)
                .foregroundStyle(Color.posSuccess)
            label(Localization.active, size: 9, weight: .bold, color: .posOnInverseSurface, width: 112)
        }
        .posPadding(.horizontal, \.small)
        .frame(width: Constants.activeMessageSize.width, height: Constants.activeMessageSize.height)
        .background(Color.posInverseSurface, in: RoundedRectangle(cornerRadius: POSCornerRadiusStyle.large.value))
    }
}

private struct AnimationKey: Equatable {
    let slide: POSGuidedAccessGuideSlide
    let reduceMotion: Bool
}

private struct Touch: Equatable {
    var point = CGPoint.zero
    var isVisible = false
    var isPressed = false
}

private struct TouchIndicator: View {
    let touch: Touch
    var pressOffset = CGSize.zero

    var body: some View {
        Circle()
            .fill(Color.posOnSurface.opacity(0.3))
            .strokeBorder(Color.posOnSurface.opacity(0.6))
            .frame(width: Constants.touchSize, height: Constants.touchSize)
            .scaleEffect(touch.isPressed && pressOffset == .zero ? 0.7 : 1)
            .offset(touch.isPressed ? pressOffset : .zero)
            .opacity(touch.isVisible ? 1 : 0)
            .position(touch.point)
    }
}

private extension Binding where Value == Touch {
    @MainActor
    func press(at point: CGPoint, leadIn: Duration = Constants.touchLeadIn) async -> Bool {
        if wrappedValue.isVisible {
            withAnimation(.easeInOut(duration: 0.3)) { wrappedValue.point = point }
        } else {
            wrappedValue.point = point
            withAnimation(.easeOut(duration: 0.2)) { wrappedValue.isVisible = true }
        }
        guard await pause(leadIn) else { return false }
        withAnimation(.easeOut(duration: 0.12)) { wrappedValue.isPressed = true }
        return await pause(Constants.touchHold)
    }

    @MainActor
    func lift(hides: Bool = true) {
        withAnimation(.easeOut(duration: 0.25)) {
            wrappedValue.isPressed = false
            wrappedValue.isVisible = wrappedValue.isVisible && !hides
        }
    }
}

@MainActor
private func block(_ width: CGFloat, _ height: CGFloat, _ color: Color, radius: CGFloat = POSCornerRadiusStyle.full.value) -> some View {
    RoundedRectangle(cornerRadius: radius).fill(color).frame(width: width, height: height)
}

@MainActor
private func card(width: CGFloat, height: CGFloat) -> some View {
    block(width, height, .posSurfaceBright, radius: POSCornerRadiusStyle.medium.value)
}

@MainActor
private func label(_ text: String, size: CGFloat, weight: Font.Weight = .regular, color: Color = .posOnSurface, width: CGFloat) -> some View {
    let scale = size / 14
    return Text(text)
        .font(weight == .bold ? POSFontStyle.posCaptionBold : .posCaptionRegular)
        .foregroundStyle(color)
        .lineLimit(2)
        .minimumScaleFactor(0.6)
        .frame(width: width / scale, height: 20 / scale, alignment: .leading)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: width, height: 20, alignment: .topLeading)
}

private func pause(_ duration: Duration) async -> Bool {
    (try? await Task.sleep(for: duration)) != nil
}

private extension View {
    func at(_ x: CGFloat, _ y: CGFloat) -> some View {
        offset(x: x, y: y)
    }

    func revealed(_ isRevealed: Bool) -> some View {
        opacity(isRevealed ? 1 : 0).offset(y: isRevealed ? 0 : 6)
    }
}

private struct Layout {
    let isPhone: Bool
    let screen: CGSize

    init(_ device: POSGuidedAccessIllustration.Device) {
        switch device {
        case .pad:
            isPhone = false
            screen = Constants.padScreen
        case .phone(let heightRatio):
            isPhone = true
            let ratio = min(max(heightRatio, Constants.phoneRatios.lowerBound), Constants.phoneRatios.upperBound)
            screen = CGSize(width: Constants.phoneWidth, height: (Constants.phoneWidth * ratio).rounded())
        }
    }

    var origin: CGPoint {
        isPhone ? CGPoint(x: 12, y: 0) : CGPoint(x: 2, y: 12)
    }

    var size: CGSize {
        CGSize(width: screen.width + 2 * origin.x, height: screen.height + origin.y)
    }

    var sidebarWidth: CGFloat {
        isPhone ? screen.width : 116
    }

    var pageX: CGFloat {
        isPhone ? 0 : sidebarWidth
    }

    var pageWidth: CGFloat {
        screen.width - pageX
    }

    var pageEntryOffset: CGFloat {
        isPhone ? pageWidth : 12
    }

    var sidebarRows: [(y: CGFloat, width: CGFloat)] {
        let rows: [(y: CGFloat, width: CGFloat)] = [(52, 46), (72, 17), (92, 31), (112, 23), (132, 14), (154, 23), (194, 39), (214, 39)]
        guard isPhone else { return rows }
        // A phone is taller than the list of the design, so more rows fill its screen.
        let extraRows = stride(from: CGFloat(234), to: screen.height - 16, by: 20).enumerated().map { index, y in
            (y: y, width: rows[index % rows.count].width)
        }
        return rows + extraRows
    }

    var extraGroups: Int {
        max(0, Int((screen.height - 40 - Constants.guidedAccessRowY) / Constants.groupPitch))
    }

    var generalShift: CGFloat {
        CGFloat(extraGroups) * Constants.groupPitch
    }

    var scrollDistance: CGFloat {
        (Constants.guidedAccessRowY + generalShift - screen.height / 2).rounded()
    }

    var volumeButtons: [CGFloat] {
        isPhone ? [70, 96] : [origin.y + 34, origin.y + 58]
    }

    var powerTouch: CGPoint {
        isPhone
            ? CGPoint(x: origin.x + screen.width + Constants.powerDepth / 2, y: 100)
            : CGPoint(x: origin.x + 53, y: origin.y - Constants.powerDepth / 2)
    }

    var powerPressOffset: CGSize {
        let travel = Constants.powerDepth - Constants.pressedPowerDepth
        return isPhone ? CGSize(width: -travel, height: 0) : CGSize(width: 0, height: travel)
    }

    var sidebarTouch: CGPoint {
        CGPoint(x: sidebarWidth / 2, y: 179)
    }

    var dragStart: CGPoint {
        CGPoint(x: pageCenterX, y: screen.height - 74)
    }

    var guidedAccessTouch: CGPoint {
        CGPoint(x: pageCenterX, y: Constants.guidedAccessRowY + generalShift - scrollDistance)
    }

    var switchTouch: CGPoint {
        CGPoint(x: pageX + pageWidth - 27, y: 52)
    }

    var passcodeRowTouch: CGPoint {
        CGPoint(x: pageCenterX, y: 115)
    }

    var setPasscodeTouch: CGPoint {
        CGPoint(x: pageCenterX, y: 52)
    }

    var keypadOrigin: CGPoint {
        CGPoint(x: ((screen.width - Constants.keypadSize.width) / 2).rounded(.down),
                y: ((screen.height - Constants.keypadSize.height) / 2).rounded(.down))
    }

    func keyOrigin(_ key: Int) -> CGPoint {
        CGPoint(x: keypadOrigin.x + 15 + CGFloat(key % 3) * 39, y: keypadOrigin.y + 15 + CGFloat(key / 3) * 41)
    }

    var activeMessageOrigin: CGPoint {
        CGPoint(x: (screen.width - Constants.activeMessageSize.width) / 2, y: (screen.height - Constants.activeMessageSize.height) / 2)
    }

    var posInset: CGFloat {
        isPhone ? 12 : 20
    }

    var posRowWidth: CGFloat {
        isPhone ? screen.width - 2 * posInset : 209
    }

    var posRows: Int {
        isPhone ? min(5, Int((screen.height - 54) / Constants.posRowPitch)) : 4
    }

    private var pageCenterX: CGFloat {
        pageX + pageWidth / 2
    }
}

private enum Constants {
    static let padScreen = CGSize(width: 375, height: 289)
    static let phoneWidth: CGFloat = 180
    // From a closed iPhone Duo, whose screen is 1.4 times taller than wide, to the tallest phones.
    static let phoneRatios: ClosedRange<CGFloat> = 1.3...2.2
    // The middle of the Guided Access row on the Accessibility page, and the distance between the groups of that page.
    static let guidedAccessRowY: CGFloat = 242
    static let groupPitch: CGFloat = 105
    static let posRowPitch: CGFloat = 53
    static let keypadSize = CGSize(width: 139, height: 144)
    static let powerLength: CGFloat = 36
    static let powerDepth: CGFloat = 4
    static let pressedPowerDepth: CGFloat = 1.5
    // Accessibility opens at step 1, its page is dragged up at step 2 and Guided Access is outlined at step 3.
    static let settingsSteps = 3
    // The passcode flow turns the switch on at step 1 and reveals the rest of its page up to step 6.
    static let passcodePageStep = 7
    static let keypadStep = 8
    static let passcodeKeys = [0, 4, 8, 5]
    static let flowSteps = keypadStep + passcodeKeys.count
    static let keySize: CGFloat = 31
    static let touchSize: CGFloat = 18
    static let startDelay: Duration = .milliseconds(600)
    static let beat: Duration = .milliseconds(450)
    static let longBeat: Duration = .milliseconds(1300)
    static let switchDelay: Duration = .milliseconds(600)
    static let typingDelay: Duration = .milliseconds(1500)
    static let loopHold: Duration = .milliseconds(2400)
    static let outlineDelay: Duration = .milliseconds(300)
    static let settingsHold: Duration = .seconds(4)
    static let activeMessageSize = CGSize(width: 152, height: 32)
    static let dragDuration: Duration = .milliseconds(800)
    static let cascadeInterval: Duration = .milliseconds(90)
    static let touchLeadIn: Duration = .milliseconds(500)
    static let touchHold: Duration = .milliseconds(200)
    static let keyLeadIn: Duration = .milliseconds(320)
    static let powerDelay: Duration = .seconds(1)
    static let clickGap: Duration = .milliseconds(300)
    static let activeMessageDelay: Duration = .milliseconds(600)
    static let activeMessageHold: Duration = .seconds(5)
    static let powerRestartDelay: Duration = .seconds(3)
    static var sceneTransition: AnyTransition { .opacity.combined(with: .scale(scale: 0.94)) }
    // Stays visible on both the device and its cards in light mode, where the dim surfaces match the background.
    static let fill = Color.posOutlineVariant.opacity(0.5)
    // The palette has no token for the blue of the Accessibility icon and of links in iOS Settings.
    static let settingsBlue = Color(uiColor: .systemBlue)
}

private enum Localization {
    static let accessibility = NSLocalizedString("pos.guidedAccessGuide.illustration.accessibility", value: "Accessibility",
                                                 comment: "Name of the Accessibility section of the iOS Settings app, shown in an illustration.")
    static let general = NSLocalizedString("pos.guidedAccessGuide.illustration.general", value: "General",
                                           comment: "Header of the group that lists Guided Access in iOS Accessibility settings, shown in an illustration.")
    static let active = NSLocalizedString("pos.guidedAccessGuide.illustration.active", value: "Guided Access Active",
                                          comment: "Message that confirms a Guided Access session has started, shown in an illustration.")
    static let setPasscode = NSLocalizedString("pos.guidedAccessGuide.illustration.setPasscode", value: "Set Guided Access Passcode",
                                               comment: "Name of the row that sets the passcode in iOS Guided Access settings, shown in an illustration.")
    static let passcodeSettings = NSLocalizedString("pos.guidedAccessGuide.illustration.passcodeSettings", value: "Passcode Settings",
                                                    comment: "Name of the passcode row in iOS Guided Access settings, shown in an illustration.")
}

#if DEBUG
#Preview("Slides, light and dark") {
    HStack {
        ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
            VStack {
                ForEach(POSGuidedAccessGuideSlide.allCases, id: \.self) { slide in
                    HStack {
                        POSGuidedAccessIllustration(slide: slide)
                        POSGuidedAccessIllustration(slide: slide, device: .phone(heightRatio: 2.17))
                        POSGuidedAccessIllustration(slide: slide, device: .phone(heightRatio: 1.4))
                    }
                }
            }
            .posPadding(\.medium)
            .background(Color.posSurfaceBright)
            .environment(\.colorScheme, scheme)
        }
    }
}
#endif
