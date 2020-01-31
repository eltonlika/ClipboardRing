//
//  StatusMenuController.swift
//  ClipboardRing
//
//  Created by Elton Lika on 5/4/19.
//  Copyright © 2019 Elton Lika. All rights reserved.
//

class StatusMenuController: NSObject, NSMenuDelegate, PasteboardWatcherDelegate {
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var clearMenuItem: NSMenuItem!
    @IBOutlet weak var pasteOnSelectionMenuItem: NSMenuItem!
    @IBOutlet weak var startAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var quitMenuItem: NSMenuItem!
    @IBOutlet weak var pasteboardWatcher: PasteboardWatcher!
    
    private let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    private var clipMenuItems : [NSMenuItem] { get { return statusMenu.items.dropLast(5) } }
    
    private var globalHotKey : DDHotKey?
    
    private var autopasteEnabled : Bool {
        get { return UserDefaults.standard.bool(forKey: "autopaste") }
        set(selected) { UserDefaults.standard.set(selected, forKey: "autopaste") }
    }
    
    // flag that when set to true skips the next pasteboard copy detection
    private var skipNextCopiedString = false
    
    // flag set to true if menu was opened from global hotkey shortcut
    private var menuOpenedFromGlobalHotkey = false
    
    private func isAccessibilityTrusted(prompt : Bool) -> Bool {
        let options : NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    override func awakeFromNib() {
        // initially there are no clipboard items, so hide the Clear button
        clearMenuItem.isHidden = true
        
        // set state of "Paste on selection" menu item
        pasteOnSelectionMenuItem.state = (autopasteEnabled && isAccessibilityTrusted(prompt: false)) ? .on : .off
        
        // set state of "Start at login" menu item
        startAtLoginMenuItem.state = LoginItems.isLoginItem() ? .on : .off
        
        // set status item appearance
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true // best for dark mode
        statusBarItem.button?.image = icon
        statusBarItem.menu = statusMenu
        statusBarItem.isVisible = true
        
        // set menu delegate
        statusMenu.delegate = self
        
        // set default hotkey handler
        globalHotKey = DDHotKey(
            keyCode: UInt16(0x09),
            modifierFlags: NSEvent.ModifierFlags.control.rawValue | NSEvent.ModifierFlags.shift.rawValue,
            task: { _ in self.globalHotkeyHandler() })
        
        // register global hotkey detection
        DDHotKeyCenter.shared()?.register(globalHotKey)
        
        // set pasteboard watcher delegate
        pasteboardWatcher.delegate = self
    }
    
    @IBAction func clearClicked(_ sender: NSMenuItem) {
        NSPasteboard.general.clearContents()
        statusMenu.items.removeFirst(statusMenu.items.count - 5)
        clearMenuItem.isHidden = true
    }
    
    @IBAction func pasteOnSelectionClicked(_ sender: NSMenuItem) {
        if sender.state == .on {
            autopasteEnabled = false
        } else {
            autopasteEnabled = isAccessibilityTrusted(prompt: true)
        }
        sender.state = autopasteEnabled ? .on : .off
    }
    
    @IBAction func startAtLoginClicked(_ sender: NSMenuItem) {
        if LoginItems.isLoginItem(){
            LoginItems.removeLoginItem()
            startAtLoginMenuItem.state = .off
        } else {
            LoginItems.addLoginItem()
            startAtLoginMenuItem.state = .on
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        DDHotKeyCenter.shared()?.unregisterHotKey(globalHotKey)
        NSApplication.shared.terminate(self)
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        // temporarily unregister global hotkey detection to prevent the menu from opening multiple times
        DDHotKeyCenter.shared()?.unregisterHotKey(globalHotKey)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // re-enable hotkey detection after menu is closed
        DDHotKeyCenter.shared()?.register(globalHotKey)
    }
    
    @objc func globalHotkeyHandler(){
        // do not show if no items
        if clipMenuItems.isEmpty {
            return
        }
        
        // temporarily hide static menu items when menu opened from global hotkey
        pasteOnSelectionMenuItem.isHidden = true
        startAtLoginMenuItem.isHidden = true
        quitMenuItem.isHidden = true
        
        menuOpenedFromGlobalHotkey = true
        
        // open menu where the mouse pointer is (this function call blocks until the menu is closed)
        statusMenu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        
        menuOpenedFromGlobalHotkey = false
        
        // unhide static menu items that were hidden when menu opened from global hotkey
        pasteOnSelectionMenuItem.isHidden = false
        startAtLoginMenuItem.isHidden = false
        quitMenuItem.isHidden = false
    }
    
    @objc func menuItemClicked(sender: NSMenuItem) {
        if let value = sender.representedObject as? String {
            // skip the next pasteboard change detection so the selected value will not be readded to the ring
            skipNextCopiedString = true
            
            // set current pasteboard string value
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(value, forType: NSPasteboard.PasteboardType.string)
            
            // update ticked status of existing menu items to OFF
            clipMenuItems.forEach {item in item.state = .off}
            
            // update ticked status of selected menu item to ON
            sender.state = .on
            
            // paste automatically only if menu opened from global hotkey
            if menuOpenedFromGlobalHotkey && autopasteEnabled {
                paste()
            }
        }
    }
    
    private func addNewClipMenuItem(newValue: String) {
        let clipItems = clipMenuItems
        let clipCount = clipItems.count
        
        if clipCount > 0 {
            // update ticked status of existing menu items to OFF
            clipItems.forEach {item in item.state = .off}
            
            // if the new value is equal to the first item then do not add a new menu item
            if let firstClipItem = clipItems.first,
                let firstValue = firstClipItem.representedObject as? String {
                if newValue == firstValue {
                    firstClipItem.state = .on
                    return
                }
            }
            
            // update the shortcut key numbers for the first 9 menu items to the next number
            for i in 0..<min(9, clipCount) {
                clipItems[i].keyEquivalent = String(i+1)
            }
            
            // if a 10th menu item exists then remove it's shortcut key because this menu item
            // is going to be pushed down to 11th position after the new item is added to the menu
            if clipCount >= 10 {
                clipItems[9].keyEquivalent = ""
            }
        }
        
        // create truncated label of the new value
        let trimmedValue = newValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let label = trimmedValue.count > 40 ? String(trimmedValue.prefix(40)) + "..." : trimmedValue
        
        // create a new menu item with shortcut "0"
        let menuItem = NSMenuItem(title: label,
                                  action: #selector(menuItemClicked(sender:)),
                                  keyEquivalent: "0")
        menuItem.keyEquivalentModifierMask = []
        menuItem.representedObject = newValue
        menuItem.target = self
        menuItem.isEnabled = true
        menuItem.toolTip = newValue
        // update ticked status of new menu item to ON
        menuItem.state = .on
        
        // insert new menu item at the top of the items
        statusMenu.insertItem(menuItem, at: 0)
        
        // unhide clear menu item
        clearMenuItem.isHidden = false
    }
    
    func newlyCopiedStringObtained(copiedString: String) {
        if skipNextCopiedString {
            skipNextCopiedString = false
            return
        }
        
        if !copiedString.isEmpty {
            addNewClipMenuItem(newValue: copiedString)
        }
    }
    
    // simulate paste event
    private func paste() {
        let event1 = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true); // cmd-v down
        event1?.flags = CGEventFlags.maskCommand;
        event1?.post(tap: CGEventTapLocation.cghidEventTap);
        
        let event2 = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false) // cmd-v up
        //event2?.flags = CGEventFlags.maskCommand
        event2?.post(tap: CGEventTapLocation.cghidEventTap)
    }
    
}
