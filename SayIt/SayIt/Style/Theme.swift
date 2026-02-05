import SwiftUI

enum Theme {
    enum Colors {
        static let base = Color(red: 0.06, green: 0.07, blue: 0.08)
        static let surface1 = Color(red: 0.08, green: 0.09, blue: 0.11)
        static let surface2 = Color(red: 0.11, green: 0.13, blue: 0.14)
        static let border = Color.white.opacity(0.06)
        static let textPrimary = Color.white.opacity(0.94)
        static let textSecondary = Color.white.opacity(0.68)
        static let textTertiary = Color.white.opacity(0.45)
        static let accent = Color(red: 1.0, green: 0.54, blue: 0.16)
        static let accentHover = Color(red: 1.0, green: 0.62, blue: 0.30)
        static let accentPressed = Color(red: 0.88, green: 0.44, blue: 0.10)
        static let accentGlow = Color(red: 1.0, green: 0.54, blue: 0.16).opacity(0.30)
        static let error = Color(red: 1.0, green: 0.35, blue: 0.35)
        static let success = Color(red: 0.35, green: 1.0, blue: 0.35)
    }

    enum Radius {
        static let card: CGFloat = 14
        static let button: CGFloat = 12
        static let input: CGFloat = 10
    }

    enum Motion {
        static let standard: Double = 0.25
    }
}
