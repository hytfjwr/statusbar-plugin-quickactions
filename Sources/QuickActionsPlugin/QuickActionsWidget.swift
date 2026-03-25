import StatusBarKit
import SwiftUI
import UserNotifications

@MainActor
@Observable
public final class QuickActionsWidget: StatusBarWidget {
    public let id = "quick-actions"
    public let position: WidgetPosition = .left
    public let updateInterval: TimeInterval? = nil
    public var sfSymbolName: String { "bolt.fill" }

    private var popupPanel: PopupPanel?

    public init() {}

    public func start() {}
    public func stop() {
        popupPanel?.hidePopup()
    }

    public typealias SettingsBody = QuickActionsSettingsView

    public var preferredSettingsSize: CGSize? { CGSize(width: 420, height: 400) }

    public func settingsBody() -> QuickActionsSettingsView {
        QuickActionsSettingsView()
    }

    public func body() -> some View {
        Image(systemName: "wrench.and.screwdriver")
            .font(Theme.sfIconFont)
            .foregroundStyle(Theme.secondary)
            .padding(.horizontal, 2)
            .contentShape(Rectangle())
            .onTapGesture { [weak self] in
                self?.togglePopup()
            }
    }

    private func togglePopup() {
        if popupPanel?.isVisible == true {
            popupPanel?.hidePopup()
        } else {
            showPopup()
        }
    }

    private func showPopup() {
        if popupPanel == nil {
            popupPanel = PopupPanel(contentRect: NSRect(x: 0, y: 0, width: 220, height: 200))
        }

        guard let (barFrame, screen) = PopupPanel.barTriggerFrame() else {
            return
        }

        let content = QuickActionsPopupContent { [weak self] in
            self?.popupPanel?.hidePopup()
        }

        popupPanel?.showPopup(relativeTo: barFrame, on: screen, content: content)
    }
}

// MARK: - QuickActionsPopupContent

struct QuickActionsPopupContent: View {
    let settings = QuickActionsSettings.shared
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PopupSectionHeader("Quick Actions")

            VStack(spacing: 2) {
                if settings.actions.isEmpty {
                    VStack(spacing: 4) {
                        Text("No actions configured.")
                        Text("Add actions in widget settings.")
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(.vertical, 12)
                } else {
                    ForEach(settings.actions) { action in
                        PopupRow(icon: action.icon, label: action.label) {
                            Task {
                                do {
                                    _ = try await ShellCommand.run(action.command)
                                } catch {
                                    await sendErrorNotification(
                                        actionLabel: action.label,
                                        error: error
                                    )
                                }
                            }
                            dismiss()
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
        }
        .frame(width: 230)
    }

    private func sendErrorNotification(actionLabel: String, error: Error) async {
        let center = UNUserNotificationCenter.current()
        let notificationSettings = await center.notificationSettings()
        if notificationSettings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert])
        }
        let content = UNMutableNotificationContent()
        content.title = "Quick Actions"
        content.body = "\(actionLabel) failed: \(error.localizedDescription)"
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
}
