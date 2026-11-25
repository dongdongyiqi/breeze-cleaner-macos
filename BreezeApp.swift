import Cocoa
import SwiftUI

class BreezeMonitor: ObservableObject {
    @Published var detectedApps: [NSRunningApplication] = []
    @Published var whitelist: Set<String> = []
    @Published var isScanning: Bool = true
    
    private var timer: Timer?
    private let whitelistKey = "BreezeSystem_Whitelist"
    
    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: whitelistKey) {
            whitelist = Set(saved)
        }
        whitelist.insert("Terminal")
        whitelist.insert("Finder")
        scanProcesses()
        startRadar()
    }
    
    func startRadar() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            guard self.isScanning else { return }
            self.scanProcesses()
        }
    }
    
    func scanProcesses() {
        let runningApps = NSWorkspace.shared.runningApplications
        let myBundleID = Bundle.main.bundleIdentifier
        
        let targets = runningApps.filter { app in
            guard app.activationPolicy == .regular,
                  app.bundleIdentifier != myBundleID,
                  let name = app.localizedName,
                  let path = app.bundleURL?.path else { return false }
            
            if path.hasPrefix("/System/") { return false }
            if whitelist.contains(name) { return false }
            return true
        }
        
        DispatchQueue.main.async {
            self.detectedApps = targets
        }
    }
    
    func killApp(_ app: NSRunningApplication) {
        app.forceTerminate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.scanProcesses()
        }
    }
    
    func allowAndRemember(_ app: NSRunningApplication) {
        if let name = app.localizedName {
            whitelist.insert(name)
            UserDefaults.standard.set(Array(whitelist), forKey: whitelistKey)
            scanProcesses()
        }
    }
}

struct ContentView: View {
    @ObservedObject var monitor: BreezeMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🍃 清风系统 v2.0")
                    .font(.headline)
                Spacer()
                Toggle("巡检", isOn: $monitor.isScanning)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            Divider()
            
            if monitor.detectedApps.isEmpty {
                Text("系统非常清爽，暂无多余软件")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                Text("检测到以下活动软件：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(monitor.detectedApps, id: \.processIdentifier) { app in
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 18, height: 18)
                        }
                        Text(app.localizedName ?? "未知应用")
                            .lineLimit(1)
                        Spacer()
                        Button("放行") {
                            monitor.allowAndRemember(app)
                        }
                        Button("清理") {
                            monitor.killApp(app)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                Text("已记住白名单: \(monitor.whitelist.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("退出系统") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 320)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var monitor = BreezeMonitor()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🍃"
            button.action = #selector(togglePopover(_:))
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 260)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView(monitor: monitor))
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
