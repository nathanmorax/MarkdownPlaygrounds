//
//  ViewController+BarAccessory.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 11/08/25.
//
import Cocoa

extension ViewController {
    
    func setupBarAccessory() {
        guard let window = view.window else {
            DispatchQueue.main.async { [weak self] in
                self?.setupBarAccessory()
            }
            return
        }
        
        configureWindowForTitlebarAccessories(window)
        
        let accessory = createTitlebarAccessory()
        window.addTitlebarAccessoryViewController(accessory)
    }
    
    private func configureWindowForTitlebarAccessories(_ window: NSWindow) {
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        
        window.styleMask.insert(.titled)
        window.styleMask.insert(.closable)
        window.styleMask.insert(.miniaturizable)
        window.styleMask.insert(.resizable)
        
    }
    
    private func createTitlebarAccessory() -> NSTitlebarAccessoryViewController {
        let stackView = createButtonStackView()
        
        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = stackView
        accessory.layoutAttribute = .right
        
        return accessory
    }
    
    private func createButtonStackView() -> NSStackView {
        let toggleButton = createToggleInspectorButton()
        let newFileButton = createNewFileButton()
        
        let stackView = NSStackView(views: [newFileButton, toggleButton])
        stackView.orientation = .horizontal
        stackView.spacing = 8
        stackView.alignment = .centerY
        stackView.distribution = .fillEqually
        
        stackView.frame = NSRect(x: 0, y: 0, width: 80, height: 32)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalToConstant: 32),
            stackView.widthAnchor.constraint(equalToConstant: 80)
        ])
        
        return stackView
    }
    
    private func createTitlebarButton(systemName: String, accessibilityDescription: String, action: Selector) -> NSButton {
        guard let icon = NSImage(systemSymbolName: systemName, accessibilityDescription: accessibilityDescription) else {
            fatalError("System icon '\(systemName)' not found")
        }
        
        let button = NSButton(image: icon, target: self, action: action)
        button.bezelStyle = .texturedRounded
        
        button.frame = NSRect(x: 0, y: 0, width: 32, height: 32)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
                
        return button
    }
    
    private func createToggleInspectorButton() -> NSButton {
        return createTitlebarButton(
            systemName: "sidebar.right",
            accessibilityDescription: "Toggle Inspector",
            action: #selector(toggleInspector)
        )
    }
    
    private func createNewFileButton() -> NSButton {
        return createTitlebarButton(
            systemName: "document.badge.plus.fill",
            accessibilityDescription: "New File",
            action: #selector(newFile)
        )
    }
}

