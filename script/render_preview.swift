import AppKit
import SwiftUI
import TodoCore

@main
struct Preview {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = TodoStore(fileURL: dir.appending(path: "tasks.json"))
        store.add("整理本周的灵感与想法")
        store.add("出去走走，买一杯喜欢的咖啡")
        store.add("完成 TodoList 的界面设计")
        if let id = store.items.first?.id { store.toggle(id) }
        for (name, scheme) in [("light", ColorScheme.light), ("dark", ColorScheme.dark)] {
            let view = NSHostingView(rootView: TaskPanel(store: store).environment(\.colorScheme, scheme))
            view.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
            view.frame = NSRect(origin: .zero, size: view.fittingSize)
            view.layoutSubtreeIfNeeded()
            guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            if let png = bitmap.representation(using: .png, properties: [:]) {
                try png.write(to: URL(fileURLWithPath: "dist/preview-\(name).png"))
            }
        }
    }
}
