//
//  StatusMenuController.swift
//  ClipboardRing
//
//  Created by Elton Lika on 5/4/19.
//  Copyright © 2019 Elton Lika. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject, PasteboardWatcherDelegate {
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var clearMenuItem: NSMenuItem!
    @IBOutlet weak var clearSeparatorItem: NSMenuItem!
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    private let pasteboardWatcher = PasteboardWatcher()
    
    override func awakeFromNib() {
        // set menu appearance
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true // best for dark mode
        statusItem.button?.image = icon
        statusItem.menu = statusMenu
        
        clearMenuItem.isHidden = true
        clearSeparatorItem.isHidden = true
        
        // start listening for pasteboard changes
        pasteboardWatcher.delegate = self
        pasteboardWatcher.startPolling()
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
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
        
        // check if first clip is equal to new value and immediately return without adding a new menu item
        if clipCount > 0 {
            if let firstValue = items.first?.representedObject as? String {
                if newValue == firstValue {
                    return
                }
            }
        }
        
        // if no elements or new value different from first value then create new menu item
        
        // create truncated label of the value
        let trimmedValue = newValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let label = trimmedValue.count > 40 ? String(trimmedValue.prefix(40)) + "..." : trimmedValue;
        
        // create menu item with shortcut Command + 0
        let menuItem = NSMenuItem(title: label, action: #selector(menuItemClicked(sender:)), keyEquivalent: "0")
        menuItem.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
        menuItem.representedObject = newValue
        menuItem.target = self
        menuItem.isEnabled = true
        
        // update shortcut numbers for the 9 existing top menu items
        if clipCount > 0 {
            for i in 0...min(8, clipCount-1) {
                items[i].keyEquivalent = String(i+1)
            }
        }
        
        // remove shortcut from existing 10th menu item
        if clipCount >= 10 {
            items[9].keyEquivalent = ""
        }
        
        // unhide clear menu item and separator
        clearMenuItem.isHidden = false
        clearSeparatorItem.isHidden = false
        
        // insert new menu item at the top of the items
        statusMenu.insertItem(menuItem, at: 0)
    }
    
    @objc func menuItemClicked(sender: NSMenuItem) {
        if let value = sender.representedObject as? String {
            // skip the next pasteboard change detection so the selected value will not be readded to the ring
            pasteboardWatcher.skipNextChange = true
            
            // set current pasteboard string value
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(value, forType: NSPasteboard.PasteboardType.string)
        }
    }
    
    func newlyCopiedStringObtained(copiedString: String) {
        if !copiedString.isEmpty {
            addNewClipMenuItem(newValue: copiedString)
        }
    }
    
}
