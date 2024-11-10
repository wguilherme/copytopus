import SwiftUI
import HotKey

@main
struct QuickLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem?
    private var hotKey: HotKey?
    private var popover: NSWindow?
    @Published var isWindowOpen = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupHotKey()
        setupPopover()
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        }
    }
    
    private func setupHotKey() {
        hotKey = HotKey(key: .space, modifiers: [.control, .option])
        hotKey?.keyDownHandler = { [weak self] in
            self?.togglePopover()
        }
    }
    
    private func setupPopover() {
        let contentView = SearchView(appDelegate: self)
        let hostingView = NSHostingView(rootView: contentView)
        
        popover = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 44),
            styleMask: [.borderless, .titled],  // Adicionado .titled para permitir foco
            backing: .buffered,
            defer: false
        )
        
        popover?.contentView = hostingView
        popover?.backgroundColor = .clear
        popover?.isOpaque = false
        popover?.hasShadow = true
        popover?.level = .floating
        popover?.animationBehavior = .utilityWindow
        popover?.isMovableByWindowBackground = true
    }
    
    private func togglePopover() {
        if popover?.isVisible == true {
            popover?.orderOut(nil)
            isWindowOpen = false
        } else {
            guard let screen = NSScreen.main else { return }
            let screenRect = screen.frame
            let popoverRect = popover?.frame ?? .zero
            
            let x = (screenRect.width - popoverRect.width) / 2
            let y = (screenRect.height - popoverRect.height) / 2
            
            popover?.setFrameOrigin(NSPoint(x: x, y: y))
            popover?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isWindowOpen = true
            
            // Força o foco após um pequeno delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

struct SearchView: View {
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    @ObservedObject var appDelegate: AppDelegate
    
    var body: some View {
        TextField("Digite algo...", text: $searchText)
            .textFieldStyle(.plain)
            .focused($isFocused)
            .onAppear {
                isFocused = true
            }
            .onChange(of: appDelegate.isWindowOpen) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                            let newPosition = CGPoint(
                                x: window.frame.origin.x + gesture.translation.width,
                                y: window.frame.origin.y - gesture.translation.height
                            )
                            window.setFrameOrigin(newPosition)
                        }
                    }
            )
    }
}
