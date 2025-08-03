//
//  NSApplication.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 02/08/25.
//
import Cocoa

extension NSApplication {
    var customMenu: NSMenu {
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        let appName = ProcessInfo.processInfo.processName
        
        appMenu.submenu?.addItem(NSMenuItem(title: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.submenu?.addItem(NSMenuItem.separator())
        
        let services = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu()  // <-- variable local, nueva instancia
        services.submenu = servicesMenu
        appMenu.submenu?.addItem(services)
        
        appMenu.submenu?.addItem(NSMenuItem.separator())
        appMenu.submenu?.addItem(NSMenuItem(title: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.submenu?.addItem(hideOthers)
        
        appMenu.submenu?.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.submenu?.addItem(NSMenuItem.separator())
        appMenu.submenu?.addItem(NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        let fileMenu = NSMenuItem()
        fileMenu.submenu = NSMenu(title: "File")
        fileMenu.submenu?.addItem(NSMenuItem(title: "New", action: #selector(NSDocumentController.newDocument(_:)), keyEquivalent: "n"))
        fileMenu.submenu?.addItem(NSMenuItem(title: "Open", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o"))
        fileMenu.submenu?.addItem(NSMenuItem.separator())
        fileMenu.submenu?.addItem(NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        fileMenu.submenu?.addItem(NSMenuItem(title: "Save…", action: #selector(NSDocument.save(_:)), keyEquivalent: "s"))
        fileMenu.submenu?.addItem(NSMenuItem(title: "Revert to Saved", action: #selector(NSDocument.revertToSaved(_:)), keyEquivalent: ""))
        
        let editMenu = NSMenuItem()
        editMenu.submenu = NSMenu(title: "Edit")
        editMenu.submenu?.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.submenu?.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.submenu?.addItem(NSMenuItem.separator())
        editMenu.submenu?.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.submenu?.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.submenu?.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.submenu?.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        
        let codeMenu = NSMenuItem()
        codeMenu.submenu = NSMenu(title: "Code")
        codeMenu.submenu?.addItem(NSMenuItem(title: "Execute", action: #selector(ViewController.execute), keyEquivalent: "e"))
        
        let windowMenu = NSMenuItem()
        windowMenu.submenu = NSMenu(title: "Window")
        windowMenu.submenu?.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        windowMenu.submenu?.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.submenu?.addItem(NSMenuItem.separator())
        windowMenu.submenu?.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "m"))
        
        let mainMenu = NSMenu(title: "Main Menu")
        mainMenu.addItem(appMenu)
        mainMenu.addItem(fileMenu)
        mainMenu.addItem(editMenu)
        mainMenu.addItem(codeMenu)
        mainMenu.addItem(windowMenu)
        return mainMenu
    }
}
