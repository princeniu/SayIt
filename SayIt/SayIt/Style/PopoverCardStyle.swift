import SwiftUI

enum PopoverCardStyle {
    static let radius: CGFloat = Theme.Radius.card
    static let borderOpacity: Double = 0.06
}

struct PopoverCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: PopoverCardStyle.radius)
                    .fill(Theme.Colors.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: PopoverCardStyle.radius)
                            .stroke(Theme.Colors.border.opacity(PopoverCardStyle.borderOpacity))
                    )
            )
    }
}

extension View {
    func popoverCard() -> some View {
        modifier(PopoverCardModifier())
    }
}
