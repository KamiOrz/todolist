import AppKit
import SwiftUI
import TodoCore

struct TaskPanel: View {
    let store: TodoStore
    @State private var newTitle = ""
    @State private var showCompleted = true
    @FocusState private var composerFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double {
        store.items.isEmpty ? 0 : Double(store.completed.count) / Double(store.items.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            composer.padding(.horizontal, 20).padding(.bottom, 18)
            if let error = store.errorMessage {
                VStack(alignment: .leading, spacing: 6) {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.red)
                        .lineLimit(4).help(error)
                    Button("重试") { store.retry() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 3) {
                    if store.items.isEmpty && !store.loadFailed {
                        emptyState
                    } else {
                        if !store.pending.isEmpty {
                            sectionLabel("待完成", count: store.pending.count)
                                .padding(.bottom, 5)
                            ForEach(store.pending) { item in
                                TaskRow(item: item, store: store)
                            }
                        } else if !store.loadFailed {
                            Label("清单已完成，歇一会儿吧", systemImage: "checkmark.seal")
                                .font(.system(size: 13)).foregroundStyle(PanelStyle.accent)
                                .frame(maxWidth: .infinity).padding(.vertical, 20)
                        }
                        if !store.completed.isEmpty {
                            Button {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                                    showCompleted.toggle()
                                }
                            } label: {
                                HStack {
                                    sectionLabel("已完成", count: store.completed.count)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9, weight: .semibold))
                                        .rotationEffect(.degrees(showCompleted ? 90 : 0))
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(showCompleted ? "折叠已完成任务" : "展开已完成任务")
                            .padding(.top, 18).padding(.bottom, 5)
                            if showCompleted {
                                ForEach(store.completed) { item in
                                    TaskRow(item: item, store: store)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
                .disabled(store.loadFailed)
            }
            .frame(height: store.items.isEmpty ? 208 : 290)
            LaunchAtLoginView()
            footer
        }
        .frame(width: 380)
        .background(.regularMaterial)
        .tint(PanelStyle.accent)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 7) {
                Text(Date.now.formatted(.dateTime.month(.wide).day().weekday(.wide).locale(Locale(identifier: "zh_CN"))))
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                Text("待办清单")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                Text(store.items.isEmpty ? "把想做的事，轻轻记下来。" : "还有 \(store.pending.count) 件事，慢慢来。")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                Circle().stroke(PanelStyle.accent.opacity(0.12), lineWidth: 4)
                Circle().trim(from: 0, to: progress)
                    .stroke(PanelStyle.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "checkmark")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(PanelStyle.accent)
            }
            .frame(width: 46, height: 46)
            .accessibilityLabel("已完成 \(store.completed.count) 项，共 \(store.items.count) 项")
            .help("已完成 \(store.completed.count) / \(store.items.count)")
        }
        .padding(.horizontal, 22).padding(.top, 24).padding(.bottom, 23)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus").font(.system(size: 13, weight: .medium))
                .foregroundStyle(PanelStyle.accent)
            TextField("添加一件待办…", text: $newTitle)
                .font(.system(size: 13)).textFieldStyle(.plain)
                .focused($composerFocused).onSubmit(add)
                .accessibilityLabel("新任务内容")
            Button(action: add) {
                Image(systemName: "arrow.turn.down.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : PanelStyle.accent)
                    .frame(width: 27, height: 25)
                    .background(PanelStyle.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("添加任务").help("回车添加")
        }
        .padding(11)
        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: PanelStyle.corner))
        .overlay {
            RoundedRectangle(cornerRadius: PanelStyle.corner)
                .strokeBorder(composerFocused ? PanelStyle.accent.opacity(0.6) : Color.primary.opacity(0.07), lineWidth: 1)
        }
        .disabled(store.loadFailed)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf")
                .font(.system(size: 27, weight: .light))
                .foregroundStyle(PanelStyle.accent)
                .frame(width: 62, height: 62)
                .background(PanelStyle.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 21))
                .padding(.bottom, 5)
            Text("留一点空间，给要做的事")
                .font(.system(size: 14, weight: .medium))
            Text("从一件小事开始，完成一件就勾掉一件。")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.top, 24)
    }

    private func sectionLabel(_ title: String, count: Int) -> some View {
        HStack(spacing: 7) {
            Text(title).font(.system(size: 11, weight: .semibold))
            Text("\(count)").font(.system(size: 10, weight: .medium, design: .rounded))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(.primary.opacity(0.05), in: Capsule())
        }
        .foregroundStyle(.secondary).padding(.horizontal, 6)
    }

    private var footer: some View {
        HStack(spacing: 7) {
            if store.deletedItem != nil {
                Text("已删除任务").foregroundStyle(.secondary)
                Button("撤销") { store.undoDelete() }
                    .keyboardShortcut("z", modifiers: .command)
                    .foregroundStyle(PanelStyle.accent)
            } else {
                Image(systemName: store.errorMessage == nil ? "checkmark.circle" : "exclamationmark.circle")
                Text(store.errorMessage == nil ? "已保存在本机" : "存储需要处理")
            }
            Spacer()
            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
            }
            .buttonStyle(QuietIconStyle()).help("退出 TodoList").accessibilityLabel("退出 TodoList")
        }
        .font(.system(size: 10)).foregroundStyle(.secondary)
        .buttonStyle(.plain)
        .padding(.horizontal, 22).padding(.vertical, 10)
        .overlay(alignment: .top) { Rectangle().fill(.primary.opacity(0.06)).frame(height: 1) }
    }

    private func add() {
        guard !store.loadFailed, !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        store.add(newTitle)
        newTitle = ""
        composerFocused = true
    }
}
