//
//  AppDelegate.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 21/07/25.
//

import Cocoa
import Ink

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        _ = MarkdownDocumentController()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = NSApp.customMenu
    }
}
