import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: AppearanceStore
    @State private var isShowingConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            appearanceOptions

            statusPanel

            Spacer(minLength: 0)

            HStack {
                Button {
                    store.refresh()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .disabled(store.isApplying)

                Spacer()

                Button {
                    confirmApply()
                } label: {
                    if store.isApplying {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("应用", systemImage: "checkmark.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.hasPendingChange || store.isApplying)
            }
        }
        .padding(24)
        .background(
            KeyboardShortcutBridge(
                isEnabled: !isShowingConfirmation && store.errorMessage == nil,
                onTab: toggleSelectedMode,
                onReturn: confirmApply
            )
        )
        .alert("即将重新启动 Finder", isPresented: $isShowingConfirmation) {
            Button("取消", role: .cancel) {}
            Button("已保存，继续", role: .destructive) {
                Task {
                    await store.applySelectedMode()
                }
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            Text("切换到\(store.selectedMode.title)外观后，本工具会重新启动 Finder。部分应用可能需要手动重启后生效，请先保存正在编辑的内容。")
        }
        .alert("操作失败", isPresented: errorBinding) {
            Button("好", role: .cancel) {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "slider.horizontal.below.rectangle")
                .font(.system(size: 34, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.gray)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text("macOS Tahoe 窗口外观设置")
                    .font(.title2.weight(.semibold))
                Text("说明：此工具可以帮助你在 Tahoe 圆润外观和 Sequoia 经典外观之间切换，切换功能仅适用于macOS26；部分应用已强制使用某种圆角或者侧边栏设定，则无法切换。")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appearanceOptions: some View {
        HStack(spacing: 14) {
            AppearanceOptionCard(
                mode: .rounded,
                isSelected: store.selectedMode == .rounded,
                isDisabled: store.isApplying
            ) {
                store.selectedMode = .rounded
            }

            AppearanceOptionCard(
                mode: .classic,
                isSelected: store.selectedMode == .classic,
                isDisabled: store.isApplying
            ) {
                store.selectedMode = .classic
            }
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
//                Image(systemName: store.currentMode.symbolName)
//                    .foregroundStyle(.secondary)
                Text("检测到当前外观为：\(store.currentMode.title)")
                    .font(.headline)

                Spacer()
                if store.hasPendingChange {
                    Label("是否打算切换外观？", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }

//            Text(store.statusMessage)
//                .font(.callout)
//                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )
    }

    private func toggleSelectedMode() {
        guard !store.isApplying else { return }
        store.selectedMode = store.selectedMode == .rounded ? .classic : .rounded
    }

    private func confirmApply() {
        guard store.hasPendingChange, !store.isApplying else { return }
        isShowingConfirmation = true
    }
}

private struct AppearanceOptionCard: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    previewImage
                        .frame(maxWidth: .infinity)
                        .aspectRatio(794 / 584, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.accentColor)
                            .padding(8)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: mode.symbolName)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    Text(mode.title)
                        .font(.headline)
                    Spacer()
                }
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.22), lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.65 : 1)
    }

    @ViewBuilder
    private var previewImage: some View {
        if let image = NSImage(named: mode.previewImageName) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

private extension AppearanceMode {
    var previewImageName: String {
        switch self {
        case .rounded:
            "AppearanceRounded"
        case .classic:
            "AppearanceClassic"
        case .custom:
            "AppearanceRounded"
        }
    }
}

private struct KeyboardShortcutBridge: NSViewRepresentable {
    let isEnabled: Bool
    let onTab: () -> Void
    let onReturn: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isEnabled: isEnabled, onTab: onTab, onReturn: onReturn)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.install(for: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isEnabled = isEnabled
        context.coordinator.onTab = onTab
        context.coordinator.onReturn = onReturn
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class Coordinator {
        var isEnabled: Bool
        var onTab: () -> Void
        var onReturn: () -> Void
        private var monitor: Any?

        init(isEnabled: Bool, onTab: @escaping () -> Void, onReturn: @escaping () -> Void) {
            self.isEnabled = isEnabled
            self.onTab = onTab
            self.onReturn = onReturn
        }

        func install(for view: NSView) {
            guard monitor == nil else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak view] event in
                guard let self,
                      self.isEnabled,
                      let window = view?.window,
                      window.isKeyWindow,
                      window.attachedSheet == nil,
                      !event.modifierFlags.containsAny(of: [.command, .option, .control])
                else {
                    return event
                }

                switch event.keyCode {
                case 48:
                    self.onTab()
                    return nil
                case 36, 76:
                    self.onReturn()
                    return nil
                default:
                    return event
                }
            }
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        deinit {
            removeMonitor()
        }
    }
}

private extension NSEvent.ModifierFlags {
    func containsAny(of flags: NSEvent.ModifierFlags) -> Bool {
        !intersection(flags).isEmpty
    }
}
