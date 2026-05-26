import SwiftUI
import UIKit

enum AppColors {
    // MARK: - Backgrounds
    static let background = Color(uiColor: .systemBackground)
    static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
    static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)
    static let backgroundElevated = Color(uiColor: .secondarySystemBackground)

    // MARK: - Message Bubbles
    static let userBubbleStart = Color(red: 0.29, green: 0.45, blue: 1.0)
    static let userBubbleEnd = Color(red: 0.47, green: 0.32, blue: 0.95)
    static let aiBubble = Color(uiColor: .secondarySystemBackground)

    static let userBubbleGradient = LinearGradient(
        colors: [userBubbleStart, userBubbleEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Text
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    static let textOnAccent = Color.white

    // MARK: - Accent
    static let accent = Color(red: 0.35, green: 0.44, blue: 1.0)
    static let accentMuted = Color(red: 0.35, green: 0.44, blue: 1.0).opacity(0.12)
    static let accentSubtle = Color(red: 0.35, green: 0.44, blue: 1.0).opacity(0.06)

    // MARK: - Borders & Separators
    static let separator = Color(uiColor: .separator)
    static let border = Color(uiColor: .opaqueSeparator)
    static let subtleBorder = Color(uiColor: .separator).opacity(0.5)

    // MARK: - Semantic
    static let error = Color(uiColor: .systemRed)
    static let success = Color(uiColor: .systemGreen)
    static let warning = Color(uiColor: .systemOrange)

    // MARK: - Code Blocks
    static let codeBackground = Color(uiColor: .systemGray6)
    static let codeHeaderBackground = Color(uiColor: .systemGray5)
    static let codeText = Color(uiColor: .label)

    // MARK: - Thread Card
    static let threadCard = Color(uiColor: .tertiarySystemBackground)
    static let threadCardBorder = Color(uiColor: .separator).opacity(0.6)

    // MARK: - Shadows
    static let shadowLight = Color.black.opacity(0.04)
    static let shadowMedium = Color.black.opacity(0.08)

    // MARK: - Avatar
    static let avatarGradientStart = Color(red: 0.35, green: 0.44, blue: 1.0)
    static let avatarGradientEnd = Color(red: 0.6, green: 0.35, blue: 0.95)
    static let avatarGradient = LinearGradient(
        colors: [avatarGradientStart, avatarGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
