import SwiftUI
import TodoCore

struct TaskRow: View {
    let item: TodoItem
    let store: TodoStore
    @State private var editing = false
    @State private var hovered = false
    @State private var draft = ""
    @FocusState private var editorFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Toggle("完成任务：\(item.title)", isOn: Binding(
                get: { item.isCompleted },
                set: { _ in store.toggle(item.id) }
            ))
            .toggleStyle(TaskCheckboxStyle())
            .labelsHidden()
            .accessibilityLabel("任务：\(item.title)")
            .help(item.isCompleted ? "恢复未完成" : "标记已完成")

            if editing {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("任务内容", text: $draft, axis: .vertical)
                        .lineLimit(1...6)
                        .textFieldStyle(.roundedBorder)
                        .focused($editorFocused)
                        .onSubmit(save)
                        .onKeyPress(.return) {
                            save()
                            return .handled
                        }
                        .onExitCommand { editing = false }
                    HStack {
                        Button("保存", action: save)
                            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Button("取消") { editing = false }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            } else {
                Text(item.title.count > 30 ? String(item.title.prefix(29)) + "…" : item.title)
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .lineLimit(2)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .help(item.title)
                Button {
                    draft = item.title
                    editing = true
                    editorFocused = true
                } label: {
                    Image(systemName: "pencil")
                }
                .foregroundStyle(.secondary)
                .opacity(hovered ? 1 : 0.5)
                .help("编辑任务")
                .accessibilityLabel("编辑任务：\(item.title)")
                Button {
                    store.delete(item.id)
                } label: {
                    Image(systemName: "trash")
                }
                .foregroundStyle(hovered ? Color.red.opacity(0.8) : Color.secondary)
                .opacity(hovered ? 1 : 0.5)
                .help("删除任务")
                .accessibilityLabel("删除任务：\(item.title)")
            }
        }
        .buttonStyle(QuietIconStyle())
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(.primary.opacity(hovered || editing ? 0.045 : 0), in: RoundedRectangle(cornerRadius: 10))
        .onHover { hovered = $0 }
    }

    private func save() {
        if store.edit(item.id, title: draft) { editing = false }
    }
}

struct TaskCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isOn ? PanelStyle.accent : Color.clear)
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(configuration.isOn ? PanelStyle.accent : Color.secondary.opacity(0.4), lineWidth: 1.3)
                if configuration.isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                }
            }
            .frame(width: 19, height: 19)
            .frame(width: 24, height: 26)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("切换任务完成状态")
        .accessibilityValue(configuration.isOn ? "已完成" : "未完成")
    }
}
