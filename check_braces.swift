import Foundation

let file = try! String(contentsOfFile: "/Users/leia/.openclaw/workspace/DailyWrite/DailyWrite/Views/ContentView.swift")
let lines = file.components(separatedBy: .newlines)

var braceCount = 0
var lineNum = 0

for line in lines {
    lineNum += 1
    let openBraces = line.filter { $0 == "{" }.count
    let closeBraces = line.filter { $0 == "}" }.count
    
    braceCount += openBraces - closeBraces
    
    if lineNum >= 535 && lineNum <= 555 {
        print("Line \(lineNum) (count=\(braceCount)): \(line.prefix(60))")
    }
}

print("\nFinal brace count: \(braceCount)")
