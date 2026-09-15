import Foundation
import Observation

@MainActor @Observable
public final class TodoStore {
    public private(set) var items: [TodoItem] = []
    public private(set) var errorMessage: String?
    public private(set) var loadFailed = false
    public private(set) var deletedItem: TodoItem?
    private let fileURL: URL

    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.applicationSupportDirectory
            .appending(path: "TodoList/tasks.json")
        load()
    }

    public var pending: [TodoItem] { sorted(items.filter { !$0.isCompleted }) }
    public var completed: [TodoItem] { sorted(items.filter(\.isCompleted)) }

    private func sorted(_ values: [TodoItem]) -> [TodoItem] {
        values.sorted {
            if $0.createdAt == $1.createdAt { return $0.id.uuidString < $1.id.uuidString }
            return $0.createdAt > $1.createdAt
        }
    }

    public func add(_ title: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !loadFailed, !title.isEmpty else { return }
        items.append(TodoItem(title: title))
        save()
    }

    @discardableResult public func edit(_ id: UUID, title: String) -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !loadFailed, !title.isEmpty, let index = items.firstIndex(where: { $0.id == id }) else { return false }
        items[index].title = title
        save()
        return true
    }

    public func toggle(_ id: UUID) {
        guard !loadFailed, let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isCompleted.toggle()
        save()
    }

    public func delete(_ id: UUID) {
        guard !loadFailed, let index = items.firstIndex(where: { $0.id == id }) else { return }
        deletedItem = items.remove(at: index)
        save()
    }

    public func undoDelete() {
        guard !loadFailed, let item = deletedItem else { return }
        items.append(item)
        deletedItem = nil
        save()
    }

    public func retry() {
        if loadFailed { load() } else { save() }
    }

    private func load() {
        do {
            let data: Data
            do {
                data = try Data(contentsOf: fileURL)
            } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
                items = []
                loadFailed = false
                errorMessage = nil
                return
            }
            let decoded = try JSONDecoder().decode([TodoItem].self, from: data)
            guard Set(decoded.map(\.id)).count == decoded.count else {
                throw CocoaError(.fileReadCorruptFile)
            }
            items = decoded
            loadFailed = false
            errorMessage = nil
        } catch {
            loadFailed = true
            errorMessage = "无法读取任务，原文件已保留。请检查数据文件后重试。\n\(error.localizedDescription)"
        }
    }

    private func save() {
        guard !loadFailed else { return }
        do {
            let data = try JSONEncoder().encode(items)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
            errorMessage = nil
        } catch {
            errorMessage = "保存失败，更改暂存在内存中。请重试，成功前不要退出。\n\(error.localizedDescription)"
        }
    }
}
