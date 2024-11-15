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
    private var windowDelegate: WindowDelegate?
    
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
    
    popover = CustomWindow(
        contentRect: NSRect(x: 0, y: 0, width: 400, height: 44),
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    
    windowDelegate = WindowDelegate(appDelegate: self)
    popover?.delegate = windowDelegate
    
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
            closePopover()
        } else {
            openPopover()
        }
    }
    
    func closePopover() {
        popover?.orderOut(nil)
        isWindowOpen = false
    }
    
    private func openPopover() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        let popoverRect = popover?.frame ?? .zero
        
        let x = (screenRect.width - popoverRect.width) / 2
        let y = (screenRect.height - popoverRect.height) / 2
        
        popover?.setFrameOrigin(NSPoint(x: x, y: y))
        popover?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isWindowOpen = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    weak var appDelegate: AppDelegate?
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func windowDidResignKey(_ notification: Notification) {
        appDelegate?.closePopover()
    }
}

struct SearchView: View {
    @StateObject private var clipboardManager = ClipboardManager()
    @State private var searchText = ""
    @State private var selectedIndex: Int? = nil 
    @FocusState private var isFocused: Bool
    @ObservedObject var appDelegate: AppDelegate
    
    private var filteredItems: [SearchItem] {
        if searchText.isEmpty {
            return clipboardManager.clipboardHistory
        }
        return clipboardManager.clipboardHistory.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }
    
     var body: some View {
        VStack(spacing: 0) {
            TextField("Search...", text: $searchText)
                .allowsHitTesting(false) 
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onAppear {
                    isFocused = true
                    searchText = ""
                    selectedIndex = nil  // Resetar seleção
                }
                .onChange(of: appDelegate.isWindowOpen) { oldValue, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    } else {
                        searchText = ""
                        selectedIndex = nil  // Resetar seleção
                    }
                }
                .onKeyPress(.upArrow) {
                    if let current = selectedIndex {
                        selectedIndex = max(0, current - 1)
                    } else if !filteredItems.isEmpty {
                        selectedIndex = filteredItems.count - 1
                    }
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    if let current = selectedIndex {
                        selectedIndex = min(filteredItems.count - 1, current + 1)
                    } else if !filteredItems.isEmpty {
                        selectedIndex = 0
                    }
                    return .handled
                }
                .onKeyPress { press in
                    if press.key == .delete || press.key == .deleteForward {
                        print("delete pressed")
                        if let selectedIndex = selectedIndex {
                            if let realIndex = clipboardManager.clipboardHistory.firstIndex(where: { item in
                                filteredItems[selectedIndex].id == item.id
                            }) {
                                clipboardManager.deleteItem(at: realIndex)
                                
                                // Ajusta o selectedIndex após a deleção
                                if filteredItems.isEmpty {
                                    self.selectedIndex = nil
                                } else {
                                    self.selectedIndex = min(selectedIndex, filteredItems.count - 1)
                                }
                            }
                        }
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress { press in
                    if press.key == .escape {
                        DispatchQueue.main.async {
                            appDelegate.closePopover()
                        }
                        return .handled
                    }
                    return .ignored
                }
                .onSubmit {
                    handleEnter()
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            
            if !filteredItems.isEmpty {
                SearchListView(
                    items: filteredItems,
                    selectedIndex: selectedIndex
                )
                .padding(.top, 4)
            }
        }
        .padding(10)
        .frame(width: 400)
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

        private func handleEnter() {
        guard let selectedIndex = selectedIndex,
              selectedIndex < filteredItems.count else { return }
        
        let selectedItem = filteredItems[selectedIndex]
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedItem.title, forType: .string)
        print("Copiado para área de transferência: \(selectedItem.title)")
        appDelegate.closePopover()
    }
}


class CustomWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
