//
//  NSFont.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 31/07/25.
//
import Cocoa

extension NSFont {
    func italic() -> NSFont {
        let fontDescriptor = self.fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: fontDescriptor, size: pointSize) ?? self
    }
    
    func bold() -> NSFont {
        let fontDescriptor = self.fontDescriptor.withSymbolicTraits(.bold)
        return NSFont(descriptor: fontDescriptor, size: pointSize) ?? self
    }
    
    func boldItalic() -> NSFont {
        let fontDescriptor = self.fontDescriptor.withSymbolicTraits([.bold, .italic])
        return NSFont(descriptor: fontDescriptor, size: pointSize) ?? self
    }
}
