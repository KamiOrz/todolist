import Foundation
import Testing
@testable import TodoCore

@MainActor
struct TodoStoreTests {
    private func temporaryURL() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appending(path: "tasks.json")
    }

    @Test func lifecycleAndPersistence() throws {
        let url = try temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = TodoStore(fileURL: url)
        #expect(!store.loadFailed)
        store.add(" \n ")
        #expect(store.items.isEmpty)
        store.add("  买牛奶  ")
        let id = try #require(store.items.first?.id)
        #expect(store.items.first?.title == "买牛奶")
        #expect(!store.edit(id, title: "  "))
        let longTitle = String(repeating: "中文长任务", count: 100)
        #expect(store.edit(id, title: longTitle))
        store.toggle(id)
        #expect(store.pending.isEmpty)
        #expect(store.completed.count == 1)
        #expect(TodoStore(fileURL: url).items == store.items)
        store.toggle(id)
        #expect(store.pending.count == 1)
        store.delete(id)
        #expect(TodoStore(fileURL: url).items.isEmpty)
        store.undoDelete()
        #expect(store.pending.first?.title == longTitle)
        #expect(TodoStore(fileURL: url).items == store.items)
        store.undoDelete()
        #expect(store.items.count == 1)
    }

    @Test func sortingAndLastDeletion() throws {
        let url = try temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let older = TodoItem(title: "旧任务", createdAt: Date(timeIntervalSince1970: 1))
        let newer = TodoItem(title: "新任务", createdAt: Date(timeIntervalSince1970: 2))
        try JSONEncoder().encode([older, newer]).write(to: url)
        let store = TodoStore(fileURL: url)
        #expect(store.pending.map(\.id) == [newer.id, older.id])
        store.delete(older.id)
        store.delete(newer.id)
        store.undoDelete()
        #expect(store.items == [newer])
    }

    @Test func damagedFileIsNeverOverwritten() throws {
        let url = try temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let damaged = Data("broken json".utf8)
        try damaged.write(to: url)
        let store = TodoStore(fileURL: url)
        #expect(store.loadFailed)
        #expect(store.errorMessage != nil)
        store.add("不能覆盖")
        store.retry()
        #expect(try Data(contentsOf: url) == damaged)
        #expect(store.items.isEmpty)
        try Data("[]".utf8).write(to: url)
        store.retry()
        #expect(!store.loadFailed)
        store.add("已恢复")
        #expect(TodoStore(fileURL: url).items.count == 1)
    }

    @Test func failedWriteCanRetryWithoutLosingMemory() throws {
        let rootFile = try temporaryURL()
        defer { try? FileManager.default.removeItem(at: rootFile.deletingLastPathComponent()) }
        let url = rootFile.appending(path: "tasks.json")
        let store = TodoStore(fileURL: url)
        try Data("block directory creation".utf8).write(to: rootFile)
        store.add("保留任务")
        #expect(store.errorMessage != nil)
        #expect(store.items.count == 1)
        try FileManager.default.removeItem(at: rootFile)
        store.retry()
        #expect(store.errorMessage == nil)
        #expect(TodoStore(fileURL: url).items == store.items)
    }

    @Test func unreadableDataAndDuplicateIDsAreProtected() throws {
        let url = try temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let unreadable = TodoStore(fileURL: url)
        #expect(unreadable.loadFailed)
        try FileManager.default.removeItem(at: url)
        let item = TodoItem(title: "重复")
        let data = try JSONEncoder().encode([item, item])
        try data.write(to: url)
        unreadable.retry()
        #expect(unreadable.loadFailed)
        unreadable.add("禁止覆盖")
        #expect(try Data(contentsOf: url) == data)
    }
}
