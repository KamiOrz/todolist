import SwiftUI

enum PanelStyle {
    static let accent = Color(red: 0.30, green: 0.53, blue: 0.43)
    static let corner: CGFloat = 12
}

struct QuietIconStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .frame(width: 26, height: 26)
            .background(.primary.opacity(configuration.isPressed ? 0.10 : 0.035), in: RoundedRectangle(cornerRadius: 7))
            .opacity(enabled ? 1 : 0.35)
            .contentShape(Rectangle())
    }
}
