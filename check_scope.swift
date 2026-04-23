import Foundation

let file = try! String(contentsOfFile: "/Users/leia/.openclaw/workspace/DailyWrite/DailyWrite/Views/ContentView.swift", encoding: .utf8)
let lines = file.components(separatedBy: .newlines)

var braceCount = 0
var maxBraceCount = 0

for (index, line) in lines.enumerated() {
    let lineNum = index + 1
    let openBraces = line.filter { $0 == "{" }.count
    let closeBraces = line.filter { $0 == "}" }.count
    
    braceCount += openBraces - closeBraces
    
    if braceCount > maxBraceCount {
        maxBraceCount = braceCount
    }
    
    // Print lines with struct/class/extension and their brace count
    if line.contains("struct ") || line.contains("class ") || line.contains("extension ") {
        print("Line \(lineNum) (count=\(braceCount)): \(line.prefix(50))")
    }
}

print("\nFinal brace count: \(braceCount)")
print("Max brace count: \(maxBraceCount)")
