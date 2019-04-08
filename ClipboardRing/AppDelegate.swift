//
//  AppDelegate.swift
//  ClipboardRing
//
//  Created by Elton Lika on 5/4/19.
//  Copyright © 2019 Elton Lika. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var pasteboardWatcher: PasteboardWatcher!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        pasteboardWatcher.startPolling()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        pasteboardWatcher.stopPolling()
    }
    
}
