import AppKit
import SwiftUI
import TodoCore

@main
struct TodoListApp: App {
    @State private var store = TodoStore()

    var body: some Scene {
        MenuBarExtra("待办清单", systemImage: "checklist") {
            TaskPanel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}
