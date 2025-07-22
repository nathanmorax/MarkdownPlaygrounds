//
//  AppDelegate.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 21/07/25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationWillFinishLaunching(_ notification: Notification) {
        _ = MarkdownDocumentController()
    }


}

class MarkdownDocumentController: NSDocumentController {
    override var documentClassNames: [String] {
        return ["MarkdownDocument"]
    }
    
    override var defaultType: String? {
        return "MarkdownDocument"
    }
    
    override func documentClass(forType typeName: String) -> AnyClass? {
        return MarkdownDocument.self
    }
    
}

@objc(MarkdownDocument)
class MarkdownDocument: NSDocument {
    
    let contentViewController = ViewController()
    
    override func makeWindowControllers() {
        let window = NSWindow(contentViewController: contentViewController)
        window.setContentSize(NSSize(width: 800, height: 800))
        
        let wc = NSWindowController(window: window)
        wc.contentViewController = contentViewController
        addWindowController(wc)
        
        window.makeKeyAndOrderFront(nil)
        
    }
    
}

final class ViewController: NSViewController {
    override func loadView() {
        self.view = NSView()
        
        
    }
    
}
