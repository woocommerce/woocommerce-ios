import SwiftUI

public enum AssistantSpacing: Sendable {
    public static let none: CGFloat = 0
    public static let xSmall: CGFloat = 4
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let xLarge: CGFloat = 24
    public static let xxLarge: CGFloat = 32
    public static let bubbleVerticalInset: CGFloat = 6
}

public enum AssistantRadius: Sendable {
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 20
    public static let bubble: CGFloat = 18
    public static let card: CGFloat = 18
}

public enum AssistantMotion: Sendable {
    public static let snap: Double = 0.20
    public static let transition: Double = 0.25
}
