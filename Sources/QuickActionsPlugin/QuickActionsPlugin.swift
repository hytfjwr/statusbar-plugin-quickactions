import StatusBarKit

@MainActor
public struct QuickActionsPlugin: StatusBarPlugin {
    public let manifest = PluginManifest(
        id: "com.statusbar.quick-actions",
        name: "Quick Actions"
    )

    public let widgets: [any StatusBarWidget]

    public init() {
        widgets = [QuickActionsWidget()]
    }
}

// MARK: - Plugin Factory

@_cdecl("createStatusBarPlugin")
public func createStatusBarPlugin() -> UnsafeMutableRawPointer {
    let box = PluginBox { QuickActionsPlugin() }
    return Unmanaged.passRetained(box).toOpaque()
}
