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

                if let data = code.data(using: .utf8) {
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
