import SwiftUI

enum AppTypography {
    // MARK: - Display
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    // MARK: - Body
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

    // MARK: - Small
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Code
    static let code = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let codeSmall = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: - Chat
    static let messageBubble = Font.system(size: 16, weight: .regular, design: .default)
    static let messageTimestamp = Font.system(size: 11, weight: .regular, design: .default)
    static let threadCardTitle = Font.system(size: 14, weight: .semibold, design: .default)
    static let threadCardMeta = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Navigation
    static let tabLabel = Font.system(size: 10, weight: .medium, design: .rounded)
    static let sectionHeader = Font.system(size: 13, weight: .semibold, design: .rounded)
}
