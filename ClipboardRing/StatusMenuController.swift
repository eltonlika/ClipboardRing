//
//  StatusMenuController.swift
//  ClipboardRing
//
//  Created by Elton Lika on 5/4/19.
//  Copyright © 2019 Elton Lika. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject, NSMenuDelegate, PasteboardWatcherDelegate {
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var clearMenuItem: NSMenuItem!
    @IBOutlet weak var clearSeparatorItem: NSMenuItem!
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    private let pasteboardWatcher = PasteboardWatcher()
    
    private var globalHotKey : DDHotKey?
    
    // flag that when set to true skips the next pasteboard copy detection
    private var skipNextCopiedString = false
    
    override func awakeFromNib() {
        // set status item appearance
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true // best for dark mode
        statusItem.button?.image = icon
        statusItem.menu = statusMenu
        statusItem.isVisible = true
        
        // set menu delegate
        statusMenu.delegate = self
        
        // initially there are no clipboard items, so hide dhe Clear button and it's separator
        clearMenuItem.isHidden = true
        clearSeparatorItem.isHidden = true
        
        // set default hotkey handler
        globalHotKey = DDHotKey(
            keyCode: UInt16(0x2A),
            modifierFlags: NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue,
            // simulate click on Status Bar item to open menu
            task: { _ in self.statusItem.button?.performClick(nil) })
        
        // register global hotkey detection
        DDHotKeyCenter.shared()?.register(globalHotKey)
        
        // start listening for pasteboard changes
        pasteboardWatcher.delegate = self
        pasteboardWatcher.startPolling()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        // temporarily unregister global hotkey detection to prevent the menu from opening multiple times
        DDHotKeyCenter.shared()?.unregisterHotKey(globalHotKey)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // re-enable hotkey detection after menu is closed
        DDHotKeyCenter.shared()?.register(globalHotKey)
    }
    
    @objc func menuItemClicked(sender: NSMenuItem) {
        if let value = sender.representedObject as? String {
            // skip the next pasteboard change detection so the selected value will not be readded to the ring
            skipNextCopiedString = true
            
            // set current pasteboard string value
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(value, forType: NSPasteboard.PasteboardType.string)
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        DDHotKeyCenter.shared()?.unregisterHotKey(globalHotKey)
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func clearClicked(_ sender: NSMenuItem) {
        statusMenu.items.removeFirst(statusMenu.items.count - 4)
        clearMenuItem.isHidden = true
        clearSeparatorItem.isHidden = true
    }
    
    private func addNewClipMenuItem(newValue: String) {
        let items = statusMenu.items;
        let clipCount = items.count - 4;
        
        if clipCount > 0 {
            // if the new value is equal to the first item then do not add a new menu item
            if let firstValue = items.first?.representedObject as? String {
                if newValue == firstValue {
                    return
                }
            }
            
            // update the shortcut key numbers for the first 9 menu items to the next number
            for i in 0...min(8, clipCount-1) {
                items[i].keyEquivalent = String(i+1)
            }
            
            // if a 10th menu item exists then remove it's shortcut key because
            // this menu item is going to be pushed down to 11th position after the new item is added to the menu
            if clipCount >= 10 {
                items[9].keyEquivalent = ""
            }
        }
        
        // create truncated label of the new value
        let trimmedValue = newValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let label = trimmedValue.count > 40 ? String(trimmedValue.prefix(40)) + "..." : trimmedValue;
        
        // create a new menu item with shortcut "0"
        let menuItem = NSMenuItem(title: label, action: #selector(menuItemClicked(sender:)), keyEquivalent: "0")
        menuItem.keyEquivalentModifierMask = []
        menuItem.representedObject = newValue
        menuItem.target = self
        menuItem.isEnabled = true
        menuItem.toolTip = newValue;
        
        // insert new menu item at the top of the items
        statusMenu.insertItem(menuItem, at: 0)
        
        // unhide clear menu item and separator
        clearMenuItem.isHidden = false
        clearSeparatorItem.isHidden = false
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
    
}
