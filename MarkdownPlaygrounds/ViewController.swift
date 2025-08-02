//
//  ViewController.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 28/07/25.
//
import Cocoa


final class ViewController: NSViewController {
    let editor = NSTextView()
    let output = NSTextView()
    var observerToken: Any?
    var codeBlocks: [CodeBlock] = []
    var repl: REPL!
    
    // Sistema de parsing incremental para mejor performance
    private let incrementalParser = IncrementalMarkdownParser()
    private var isUpdatingText = false // Evitar loops infinitos
    
    override func loadView() {
        let editorSV = editor.configureAndWrapInScrollView(isEditable: true, inset: CGSize(width: 20, height: 15))
        let outputSV = output.configureAndWrapInScrollView(isEditable: false, inset: CGSize(width: 15, height: 15))
        outputSV.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        editor.allowsUndo = true
        
        // Configurar colores y fuentes
        editor.backgroundColor = NSColor.controlBackgroundColor
        output.backgroundColor = NSColor.controlBackgroundColor
        
        // Mejorar la experiencia de escritura
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.isAutomaticTextReplacementEnabled = false
        
        self.view = Boilerplate().splitView([editorSV, outputSV])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupREPL()
        setupTextChangeObserver()
        
         let initialContent = """
         # Mi Markdown Playground

         Bienvenido a tu playground de Markdown. Aquí puedes probar todos los elementos soportados.

         ## Estilos de Texto

         Este es un **texto en negrita** para resaltar información importante.

         Este texto está en *cursiva* para dar énfasis.

         Este texto combina ***negrita y cursiva*** para máximo impacto.

         También puedes usar `código inline` para mencionar variables o funciones.

         ### Diferentes Niveles de Headers

         # Header Nivel 1 - El más grande
         ## Header Nivel 2 - Grande
         ### Header Nivel 3 - Mediano
         #### Header Nivel 4 - Pequeño
         ##### Header Nivel 5 - Más pequeño
         ###### Header Nivel 6 - El más pequeño

         ## Listas y Elementos

         ### Lista con guiones
         - Primera tarea pendiente
         - Segunda tarea con **texto en negrita**
         - Tercera tarea con *texto en cursiva*
         - Cuarta tarea con `código inline`
         - Quinta tarea con ***negrita y cursiva***

         ### Lista con asteriscos
         * Elemento uno
         * Elemento dos con [enlace](https://example.com)
         * Elemento tres

         ### Lista con signos más
         + Opción A
         + Opción B
         + Opción C

         ## Citas y Referencias

         > Esta es una cita importante
         > que se extiende por varias líneas
         > y demuestra cómo se ve el formato de quote.

         > Otra cita con **negrita** y *cursiva* dentro.

         ## Código y Programación

         ### Código Swift
         ```swift
         print("¡Hola mundo!")
         let numero = 42
         let nombre = "Swift"
         print("El número es: \\(numero)")
         print("Lenguaje: \\(nombre)")

         // Función de ejemplo
         func saludar(nombre: String) -> String {
             return "Hola, \\(nombre)!"
         }

         let saludo = saludar(nombre: "Desarrollador")
         print(saludo)
         ```

         ### Otro bloque de código
         ```
         // Código sin especificar lenguaje
         var x = 10
         var y = 20
         var suma = x + y
         ```

         ## Combinaciones y Casos Especiales

         Texto normal con **palabras en negrita** mezcladas, *palabras en cursiva*, y `código inline` en la misma línea.

         Una línea con ***negrita y cursiva***, seguida de **solo negrita**, después *solo cursiva*, y finalmente `solo código`.

         ### Enlaces y Referencias

         Aquí hay un [enlace a ejemplo](https://www.example.com) en el texto.

         Otro [enlace con texto más largo](https://www.github.com) para probar.

         ## Texto de Prueba para Desarrollo

         **Prueba de negrita** - *Prueba de cursiva* - ***Prueba de ambos*** - `Prueba de código`

         Línea con múltiples elementos: **negrita1** y *cursiva1* y ***ambos1*** y `código1` y **negrita2**.

         ### Casos Edge

         **b** - *i* - ***bi*** - `c` - Elementos muy cortos

         **Texto muy largo en negrita que se extiende por múltiples palabras para probar el renderizado**

         *Texto muy largo en cursiva que también se extiende por múltiples palabras*

         ***Texto muy largo en negrita y cursiva combinadas para verificar que funciona correctamente***

         ## Final

         ¡Prueba escribiendo tu propio markdown aquí! Todos estos elementos deberían renderizarse correctamente con estilos visuales distintivos.
         """
        
        editor.string = initialContent
        parse()
    }
    
    private func setupREPL() {
        repl = REPL(onStdOut: { [weak self] text in
            DispatchQueue.main.async {
                self?.output.textStorage?.append(NSAttributedString(string: text, attributes: [
                    .foregroundColor: NSColor.labelColor,
                    .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
                ]))
                self?.output.scrollToEndOfDocument(nil)
            }
        }, onStdErr: { [weak self] text in
            DispatchQueue.main.async {
                self?.output.textStorage?.append(NSAttributedString(string: text, attributes: [
                    .foregroundColor: NSColor.systemRed,
                    .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
                ]))
                self?.output.scrollToEndOfDocument(nil)
            }
        })
    }
    
    private func setupTextChangeObserver() {
        observerToken = NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeNotification,
            object: editor,
            queue: nil
        ) { [weak self] _ in
            // Pequeño delay para evitar demasiadas actualizaciones
            DispatchQueue.main.async {
                self?.parse()
            }
        }
    }

    // MARK: - Parsing y Rendering Principal
    func parse() {
        
        guard let textStorage = editor.textStorage,
              !isUpdatingText else { return }
        
        isUpdatingText = true
        defer { isUpdatingText = false }
        
        let currentText = textStorage.string
        let selectedRange = editor.selectedRange()
        
        // Usar el parser incremental para mejor performance
        let elements = incrementalParser.parseIfNeeded(currentText)
        
        // Crear una copia mutable para aplicar estilos
        let mutableString = NSMutableAttributedString(string: currentText)
        mutableString.applyMarkdownStyling(elements: elements)
        
        // Actualizar el textStorage preservando la selección
        textStorage.setAttributedString(mutableString)
        
        // Restaurar la posición del cursor de manera segura
        let safeRange = NSRange(
            location: min(selectedRange.location, textStorage.length),
            length: min(selectedRange.length, textStorage.length - min(selectedRange.location, textStorage.length))
        )
        editor.setSelectedRange(safeRange)
        
        // Actualizar code blocks para ejecución
        updateCodeBlocks(from: elements)
    }
    
    private func updateCodeBlocks(from elements: [MarkdownParser.MarkdownElement]) {
        codeBlocks = elements.compactMap { element in
            if case .codeBlock = element.type {
                return CodeBlock(text: element.content, range: element.range)
            }
            return nil
        }
    }
    
    // MARK: - Métodos legacy (mantenidos para compatibilidad)
    private func extractCodeBlocks(from markdown: String) -> [CodeBlock] {
        var blocks: [CodeBlock] = []
        let text = markdown as NSString
        
        let pattern = "```(?:swift)?\\n([\\s\\S]*?)\\n```"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: text.length))
            
            for match in matches {
                if match.numberOfRanges >= 2 {
                    let contentRange = match.range(at: 1)
                    let content = text.substring(with: contentRange)
                    blocks.append(CodeBlock(text: content, range: contentRange))
                }
            }
        } catch {
            print("Error en regex: \(error)")
            return extractCodeBlocksManually(from: markdown)
        }
        
        return blocks
    }
    
    private func extractCodeBlocksManually(from markdown: String) -> [CodeBlock] {
        var blocks: [CodeBlock] = []
        let lines = markdown.components(separatedBy: .newlines)
        var currentBlockLines: [String] = []
        var inCodeBlock = false
        var blockStartIndex = 0
        
        for (lineIndex, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCodeBlock {
                    // Fin del bloque
                    let blockContent = currentBlockLines.joined(separator: "\n")
                    let range = calculateRangeForLines(from: blockStartIndex, to: lineIndex - 1, in: markdown)
                    blocks.append(CodeBlock(text: blockContent, range: range))
                    currentBlockLines = []
                    inCodeBlock = false
                } else {
                    // Inicio del bloque
                    inCodeBlock = true
                    blockStartIndex = lineIndex + 1
                    currentBlockLines = []
                }
            } else if inCodeBlock {
                currentBlockLines.append(line)
            }
        }
        
        return blocks
    }
    
    private func calculateRangeForLines(from startLine: Int, to endLine: Int, in text: String) -> NSRange {
        let lines = text.components(separatedBy: .newlines)
        guard startLine < lines.count && endLine < lines.count else {
            return NSRange(location: 0, length: 0)
        }
        
        let beforeLines = Array(lines[0..<startLine])
        let targetLines = Array(lines[startLine...endLine])
        
        let startOffset = beforeLines.joined(separator: "\n").count + (startLine > 0 ? 1 : 0)
        let length = targetLines.joined(separator: "\n").count
        
        return NSRange(location: startOffset, length: length)
    }
    
    // MARK: - Ejecución de código
    @objc func execute() {
        let cursorPosition = editor.selectedRange().location
        
        guard let block = codeBlocks.first(where: { $0.range.contains(cursorPosition) }) else {
            output.textStorage?.setAttributedString(NSAttributedString(string: "❌ Coloca el cursor dentro de un bloque de código Swift\n\n", attributes: [
                .foregroundColor: NSColor.systemOrange,
                .font: NSFont.boldSystemFont(ofSize: 12)
            ]))
            return
        }
        
        output.textStorage?.mutableString.setString("")
        output.textStorage?.append(NSAttributedString(string: "🚀 Ejecutando código...\n\n", attributes: [
            .foregroundColor: NSColor.systemGreen,
            .font: NSFont.boldSystemFont(ofSize: 12)
        ]))
        
        repl.execute(block.text)
    }
    
    deinit {
        if let t = observerToken {
            NotificationCenter.default.removeObserver(t)
        }
    }
}
