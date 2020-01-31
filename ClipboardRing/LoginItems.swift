//
//  LoginServiceKit.swift
//  ClipboardRing
//
//  Created by Elton Lika on 31/1/20.
//  Copyright © 2020 Elton Lika. All rights reserved.
//

public final class LoginItems: NSObject {}

public extension LoginItems {
    
    static func isLoginItem(_ path: String = Bundle.main.bundlePath) -> Bool {
        return (loginItem( path) != nil)
    }
    
    @discardableResult
    static func addLoginItem(_ path: String = Bundle.main.bundlePath) -> Bool {
        guard !isLoginItem(path) else { return false }
        guard let sharedFileList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil) else { return false }
        let loginItemList = sharedFileList.takeRetainedValue()
        let url = URL(fileURLWithPath: path)
        LSSharedFileListInsertItemURL(loginItemList, kLSSharedFileListItemBeforeFirst.takeRetainedValue(), nil, nil, url as CFURL, nil, nil)
        return true
    }
    
    @discardableResult
    static func removeLoginItem(_ path: String = Bundle.main.bundlePath) -> Bool {
        guard isLoginItem(path) else { return false }
        guard let sharedFileList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil) else { return false }
        let loginItemList = sharedFileList.takeRetainedValue()
        let url = URL(fileURLWithPath: path)
        let loginItemsListSnapshot: NSArray = LSSharedFileListCopySnapshot(loginItemList, nil).takeRetainedValue()
        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return false }
        for loginItem in loginItems {
            guard let resolvedUrl = LSSharedFileListItemCopyResolvedURL(loginItem, 0, nil) else { continue }
            let itemUrl = resolvedUrl.takeRetainedValue() as URL
            guard url.absoluteString == itemUrl.absoluteString else { continue }
            LSSharedFileListItemRemove(loginItemList, loginItem)
        }
        return true
    }
    
}

private extension LoginItems {
    
    static func loginItem(_ path: String) -> LSSharedFileListItem? {
        guard !path.isEmpty else { return nil }
        guard let sharedFileList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil) else { return nil }
        let loginItemList = sharedFileList.takeRetainedValue()
        let url = URL(fileURLWithPath: path)
        let loginItemsListSnapshot: NSArray = LSSharedFileListCopySnapshot(loginItemList, nil).takeRetainedValue()
        guard let loginItems = loginItemsListSnapshot as? [LSSharedFileListItem] else { return nil }
        for loginItem in loginItems {
            guard let resolvedUrl = LSSharedFileListItemCopyResolvedURL(loginItem, 0, nil) else { continue }
            let itemUrl = resolvedUrl.takeRetainedValue() as URL
            guard url.absoluteString == itemUrl.absoluteString else { continue }
            return loginItem
        }
        return nil
    }
    
}
