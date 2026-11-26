import Cocoa
import SwiftUI

struct ProcItem: Identifiable {
    let id: pid_t
    let name: String
    let icon: NSImage
    let runningApp: NSRunningApplication?
}

class BreezeMonitor: ObservableObject {
    @Published var detectedProcs: [ProcItem] = []
    @Published var whitelist: Set<String> = []
    @Published var isScanning: Bool = true
    
    private var timer: Timer?
    private let whitelistKey = "BreezeSystem_Whitelist"
    
    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: whitelistKey) {
            whitelist = Set(saved)
        }
        ["Terminal", "Finder", "BreezeSystem"].forEach { whitelist.insert($0) }
        scanProcesses()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isScanning else { return }
            self.scanProcesses()
        }
    }
    
    func scanProcesses() {
        var list: [ProcItem] = []
        var seenPids = Set<pid_t>()
        let myPid = getpid()
        
        // 1. 扫描常规图形界面 App
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  app.processIdentifier != myPid,
                  let name = app.localizedName,
                  let path = app.bundleURL?.path,
                  !path.hasPrefix("/System/"),
                  !whitelist.contains(name) else { continue }
            
            seenPids.insert(app.processIdentifier)
            list.append(ProcItem(
                id: app.processIdentifier,
                name: name,
                icon: app.icon ?? NSWorkspace.shared.icon(forFile: path),
                runningApp: app
            ))
        }
        
        // 2. 扫描用户目录下的命令行后台进程（如《清风系统1》）
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-eo", "pid,comm"]
        let pipe = Pipe()
        task.standardOutput = pipe
        if (try? task.run()) != nil {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    let parts = trimmed.split(separator: " ", maxSplits: 1)
                    if parts.count == 2, let pid = pid_t(parts[0]), pid != myPid, !seenPids.contains(pid) {
                        let path = String(parts[1])
                        let name = URL(fileURLWithPath: path).lastPathComponent
                        // 仅捕获用户目录下非系统核心的自定义运行程序
                        if path.hasPrefix("/Users/") && !path.contains(".app/") && !whitelist.contains(name) {
                            let defaultIcon = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: nil) ?? NSImage()
                            list.append(ProcItem(id: pid, name: "\(name) (后台进程)", icon: defaultIcon, runningApp: nil))
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async { self.detectedProcs = list }
    }
    
    func killProc(_ item: ProcItem) {
        if let app = item.runningApp {
            app.forceTerminate()
        } else {
            kill(item.id, SIGKILL)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.scanProcesses() }
    }
    
    func allowAndRemember(_ item: ProcItem) {
        let cleanName = item.name.replacingOccurrences(of: " (后台进程)", with: "")
        whitelist.insert(cleanName)
        UserDefaults.standard.set(Array(whitelist), forKey: whitelistKey)
        scanProcesses()
    }
}

struct ContentView: View {
    @ObservedObject var monitor: BreezeMonitor
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🍃 清风系统 v2.1").font(.headline)
                Spacer()
                Toggle("巡检", isOn: $monitor.isScanning).toggleStyle(.switch).labelsHidden()
            }
            Divider()
            if monitor.detectedProcs.isEmpty {
                Text("系统非常清爽，暂无多余软件").foregroundColor(.secondary).padding(.vertical, 8)
            } else {
                Text("检测到以下活动软件与后台进程：").font(.caption).foregroundColor(.secondary)
                ForEach(monitor.detectedProcs) { item in
                    HStack {
                        Image(nsImage: item.icon).resizable().frame(width: 18, height: 18)
                        Text(item.name).lineLimit(1)
                        Spacer()
                        Button("放行") { monitor.allowAndRemember(item) }
                        Button("清理") { monitor.killProc(item) }.foregroundColor(.red)
                    }
                }
            }
            Divider()
            HStack {
                Text("已记住白名单: \(monitor.whitelist.count) 个").font(.caption).foregroundColor(.secondary)
                Spacer()
                Button("退出系统") { NSApplication.shared.terminate(nil) }.buttonStyle(.plain).foregroundColor(.secondary)
            }
        }.padding().frame(width: 340)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!; var popover: NSPopover!; var monitor = BreezeMonitor()
    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🍃"
        statusItem.button?.action = #selector(togglePopover(_:))
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 260)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView(monitor: monitor))
    }
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let btn = statusItem.button else { return }
        if popover.isShown { popover.performClose(sender) }
        else { monitor.scanProcesses(); popover.show(relativeTo: btn.bounds, of: btn, preferredEdge: .minY) }
    }
}

let app = NSApplication.shared; let del = AppDelegate(); app.delegate = del; app.run()
