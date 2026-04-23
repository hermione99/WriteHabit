import Foundation

let file = try! String(contentsOfFile: "/Users/leia/.openclaw/workspace/DailyWrite/DailyWrite/Views/ContentView.swift", encoding: .utf8)
let lines = file.components(separatedBy: .newlines)

var braceCount = 0
var lineNum = 0

for line in lines {
    lineNum += 1
    
    // Count braces
    let openBraces = line.filter { $0 == "{" }.count
    let closeBraces = line.filter { $0 == "}" }.count
    
    let oldCount = braceCount
    braceCount += openBraces - closeBraces
    
    // Only print if count changes significantly or struct/class/extension
    if line.contains("struct ") || line.contains("class ") || line.contains("extension ") || 
       line.contains("func ") || oldCount != braceCount {
        print("Line \(lineNum) (was \(oldCount), now \(braceCount)): \(line.prefix(60))")
    }
}

print("\nFinal brace count: \(braceCount)")
