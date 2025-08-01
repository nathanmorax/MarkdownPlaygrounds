//
//  MarkdownParser.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 31/07/25.
//
import Cocoa

class MarkdownParser {
    
    struct MarkdownElement {
        let type: ElementType
        let range: NSRange
        let level: Int? // Para headers
        let content: String
        
        enum ElementType {
            case header(Int)
            case bold
            case italic
            case code
            case codeBlock
            case link
            case list
            case quote
            case strikethrough
        }
    }
    
    func parseElements(from text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let nsText = text as NSString
        
        // Headers (# ## ###)
        elements.append(contentsOf: parseHeaders(in: nsText))
        
        // Bold (**text**)
        elements.append(contentsOf: parseBold(in: nsText))
        
        // Italic (*text*)
        
        elements.append(contentsOf: parseItalic(in: nsText))
        
        // Inline code (`code`)
        elements.append(contentsOf: parseInlineCode(in: nsText))
        
        // Code blocks (```code```)
        elements.append(contentsOf: parseCodeBlocks(in: nsText))
        
        // Links ([text](url))
        elements.append(contentsOf: parseLinks(in: nsText))
        
        // Lists (- item)
        elements.append(contentsOf: parseLists(in: nsText))
        
        // Quotes (> text)
        elements.append(contentsOf: parseQuotes(in: nsText))
        
        return elements.sorted { $0.range.location < $1.range.location }
    }
    
    private func parseHeaders(in text: NSString) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let pattern = "^(#{1,6})\\s+(.+)$"
        
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        let matches = regex.matches(in: text as String, options: [], range: NSRange(location: 0, length: text.length))
        
        for match in matches {
            let fullRange = match.range // Todo el match incluyendo # y texto
            let hashRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let level = text.substring(with: hashRange).count
            let content = text.substring(with: contentRange)
            
            elements.append(MarkdownElement(
                type: .header(level),
                range: fullRange, // Usar el rango completo
                level: level,
                content: content
            ))
        }
        
        return elements
    }
    
    private func parseBold(in text: NSString) -> [MarkdownElement] {
        return parsePattern("\\*\\*([^*]+?)\\*\\*", type: .bold, in: text)
    }
    
    private func parseItalic(in text: NSString) -> [MarkdownElement] {
        return parsePattern("(?<!\\*)\\*([^*]+?)\\*(?!\\*)", type: .italic, in: text)
    }
    
    private func parseInlineCode(in text: NSString) -> [MarkdownElement] {
        return parsePattern("`([^`]+)`", type: .code, in: text)
    }
    
    private func parseCodeBlocks(in text: NSString) -> [MarkdownElement] {
        let pattern = "```[\\w]*\\n([\\s\\S]*?)\\n```"
        return parsePattern(pattern, type: .codeBlock, in: text)
    }
    
    private func parseLinks(in text: NSString) -> [MarkdownElement] {
        return parsePattern("\\[([^\\]]+)\\]\\([^)]+\\)", type: .link, in: text)
    }
    
    private func parseLists(in text: NSString) -> [MarkdownElement] {
        return parsePattern("^[-*+]\\s+(.+)$", type: .list, in: text, options: [.anchorsMatchLines])
    }
    
    private func parseQuotes(in text: NSString) -> [MarkdownElement] {
        return parsePattern("^>\\s+(.+)$", type: .quote, in: text, options: [.anchorsMatchLines])
    }
    
    private func parsePattern(_ pattern: String, type: MarkdownElement.ElementType, in text: NSString, options: NSRegularExpression.Options = []) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        let matches = regex.matches(in: text as String, options: [], range: NSRange(location: 0, length: text.length))
        
        for match in matches {
            let contentRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
            let content = text.substring(with: contentRange)
            
            elements.append(MarkdownElement(
                type: type,
                range: match.range,
                level: nil,
                content: content
            ))
        }
        
        return elements
    }
}
