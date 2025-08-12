//
//  REPL.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 28/07/25.
//
import Cocoa

final class REPL {
    private let onStdOut: (String) -> ()
    private let onStdErr: (String) -> ()

    init(onStdOut: @escaping (String) -> (), onStdErr: @escaping (String) -> ()) {
        self.onStdOut = onStdOut
        self.onStdErr = onStdErr
    }
    
    func wrapLastExpressionInPrint(_ code: String) -> String {
        let lines = code.components(separatedBy: .newlines)
        guard !lines.isEmpty else { return code }

        // Buscar la última línea no vacía
        var lastIndex = lines.count - 1
        while lastIndex >= 0 && lines[lastIndex].trimmingCharacters(in: .whitespaces).isEmpty {
            lastIndex -= 1
        }

        guard lastIndex >= 0 else { return code }

        let lastLine = lines[lastIndex].trimmingCharacters(in: .whitespaces)

        // Detectar si es una declaración de variable
        let variablePrefixes = ["let", "var"]
        for prefix in variablePrefixes {
            if lastLine.hasPrefix(prefix) {
                // Extraer nombre de variable
                let components = lastLine.components(separatedBy: .whitespaces)
                if components.count >= 2 {
                    let variableName = components[1].components(separatedBy: "=")[0].trimmingCharacters(in: .whitespaces)
                    return code + "\nprint(\(variableName))"
                }
            }
        }

        // Si no es declaración, aplicar heurística de expresión
        let keywords = ["func", "class", "struct", "enum", "import", "return", "if", "while", "for", "switch", "guard", "do", "try", "throw"]
        let isExpression = !keywords.contains { lastLine.hasPrefix($0) }

        if isExpression {
            var modifiedLines = lines
            modifiedLines[lastIndex] = "print(\(lastLine))"
            return modifiedLines.joined(separator: "\n")
        } else {
            return code
        }
    }


    func execute(_ code: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let process = Process()
            let stdOut = Pipe()
            let stdErr = Pipe()
            let stdIn = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
            process.arguments = ["-"]
            process.standardInput = stdIn
            process.standardOutput = stdOut
            process.standardError = stdErr

            do {
                try process.run()

                guard let transformedCode = self?.wrapLastExpressionInPrint(code) else { return }
                
                if let data = transformedCode.data(using: .utf8) {
                    stdIn.fileHandleForWriting.write(data)
                }
                stdIn.fileHandleForWriting.closeFile()

                let outputData = stdOut.fileHandleForReading.readDataToEndOfFile()
                let errorData = stdErr.fileHandleForReading.readDataToEndOfFile()

                process.waitUntilExit()

                if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
                    self?.onStdOut(output)
                } else {
                    self?.onStdOut("✅ Código ejecutado (sin salida)\n")
                }

                if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
                    self?.onStdErr("❌ Error:\n\(error)\n")
                }
            } catch {
                self?.onStdErr("❌ Error ejecutando Swift: \(error)\n")
            }
        }
    }

}
