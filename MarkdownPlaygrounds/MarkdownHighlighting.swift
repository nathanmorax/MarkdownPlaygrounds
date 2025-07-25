//
//  CodeBlock.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 22/07/25.
//

import AppKit
import CommonMark
import Ccmark

extension NSMutableAttributedString {
    var range: NSRange { return NSMakeRange(0, length) }
    
    func highlightMarkdown() -> [CodeBlock] {
        let node = Node(markdown: string)
        
        let lineOffsets = string.lineOffsets
        var codeBlocks: [CodeBlock] = []
        
        func index(of pos: Position) -> String.Index {
            let lineStart = lineOffsets[Int(pos.line-1)]
            return string.index(lineStart, offsetBy: Int(pos.column-1), limitedBy: string.endIndex) ?? string.endIndex
        }
        
        let defaultAttributes = Attributes(family: "Helvetica", size: 16)
        setAttributes(defaultAttributes.atts, range: range)
        
        node.visitAll(defaultAttributes) { c, attributes in
            let start = index(of: c.start)
            let end = index(of: c.end)
            guard start < end else { return }
            let nsRange = NSRange(start...end, in: string)
            switch c.type {
            case CMARK_NODE_HEADING:
                attributes.textColor = accentColors[1]
                attributes.size = defaultAttributes.size + 2 + (CGFloat(6-c.headerLevel)*1.7)
                addAttribute(.foregroundColor, value: attributes.textColor, range: nsRange)
                addAttribute(.font, value: attributes.font, range: nsRange)
            case CMARK_NODE_EMPH:
                attributes.italic = true
                addAttribute(.font, value: attributes.font, range: nsRange)
            case CMARK_NODE_STRONG:
                attributes.bold = true
                addAttribute(.font, value: attributes.font, range: nsRange)
            case CMARK_NODE_LINK:
                attributes.textColor = .linkColor
                addAttribute(.foregroundColor, value: attributes.textColor, range: nsRange)
                if let s = c.urlString, let u = URL(string: s) {
                    addAttribute(.link, value: u, range: nsRange)
                }
            case CMARK_NODE_CODE:
                attributes.family = "Monaco"
                addAttribute(.font, value: attributes.font, range: nsRange)
            case CMARK_NODE_BLOCK_QUOTE:
                attributes.family = "Georgia"
                attributes.setIndent(defaultAttributes.size)
                addAttribute(.font, value: attributes.font, range: nsRange)
                addAttribute(.paragraphStyle, value: attributes.paragraphStyle, range: nsRange)
            case CMARK_NODE_LIST:
                attributes.setIndent(defaultAttributes.size)
                addAttribute(.paragraphStyle, value: attributes.paragraphStyle, range: nsRange)
            case CMARK_NODE_CODE_BLOCK:
                addAttribute(.backgroundColor, value: NSColor.windowBackgroundColor, range: nsRange)
                addAttribute(.font, value: NSFont(name: "Monaco", size: attributes.size)!, range: nsRange)
                codeBlocks.append(CodeBlock(text: c.literal!, range: nsRange))
            default:
                break
            }
        }
        return codeBlocks
    }
}

struct CodeBlock {
    var text: String
    var range: NSRange
}

