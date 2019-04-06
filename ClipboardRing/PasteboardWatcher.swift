//
//  ClipboardWrapper.swift
//  ClipboardRing
//
//  Created by Elton Lika on 5/4/19.
//  Copyright © 2019 Elton Lika. All rights reserved.
//

import Cocoa

/// Protocol defining the methods which delegate should implement
protocol PasteboardWatcherDelegate {
    /// the method which is invoked on delegate when a new string is copied
    /// - Parameter copiedString: the newly copied string
    func newlyCopiedStringObtained(copiedString : String)
}

class PasteboardWatcher : NSObject {
    
    private let pasteboard = NSPasteboard.general
    
    private var lastChangeCount = 0
    
    private var timer : Timer?
    
    public var delegate : PasteboardWatcherDelegate?
    
    public func startPolling() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: timerFired)
        }
    }
    
    private func timerFired(t : Timer){
        // assigning current pasteboard changeCount so that it can be compared later to identify changes
        let newChangeCount = pasteboard.changeCount
        
        if newChangeCount == lastChangeCount {
            return;
        }
        
        lastChangeCount = newChangeCount;
        
        if let copiedStr = pasteboard.string(forType: NSPasteboard.PasteboardType.string) {
            delegate?.newlyCopiedStringObtained(copiedString: copiedStr)
        }
    }
    
}
