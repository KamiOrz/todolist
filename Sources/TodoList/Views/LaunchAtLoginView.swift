import AppKit
import ServiceManagement
import SwiftUI

struct LaunchAtLoginView: View {
    @State private var statusCode: Int = SMAppService.mainApp.status.rawValue

    private var status: SMAppService.Status {
        SMAppService.Status(rawValue: statusCode) ?? .notRegistered
    }
    @State private var errorMessage: String?

    private var isRegistered: Bool {
        status == .enabled || status == .requiresApproval
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(get: { isRegistered }, set: { update($0) })) {
                HStack(spacing: 9) {
                    Image(systemName: "sunrise")
                        .foregroundStyle(PanelStyle.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("开机启动").font(.system(size: 12, weight: .medium))
                        Text(status == .requiresApproval ? "等待系统允许，尚未生效" : "登录 Mac 后自动打开")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .accessibilityValue(status == .requiresApproval ? "等待系统允许" : (status == .enabled ? "已开启" : "已关闭"))

            if status == .requiresApproval {
                Button("前往系统设置允许") {
                    SMAppService.openSystemSettingsLoginItems()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11)).foregroundStyle(PanelStyle.accent)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 10)).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22).padding(.vertical, 12)
        .overlay(alignment: .top) { Rectangle().fill(.primary.opacity(0.06)).frame(height: 1) }
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in refresh() }
    }

    private func refresh() {
        statusCode = SMAppService.mainApp.status.rawValue
    }

    private func update(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = "设置失败，请重试：\(error.localizedDescription)"
        }
        refresh()
    }
}
