#!/usr/bin/env python3
import sys

with open(sys.argv[1], 'r') as f:
    lines = f.readlines()

brace_count = 0
issues = []
for i, line in enumerate(lines, 1):
    for char in line:
        if char == '{':
            brace_count += 1
        elif char == '}':
            brace_count -= 1
            if brace_count < 0:
                issues.append(f"Line {i}: negative brace count ({brace_count})")
    if i % 50 == 0:
        print(f"Line {i}: brace_count={brace_count}")

print(f"\nFinal brace count: {brace_count}")
if issues:
    print("\nIssues found:")
    for issue in issues:
        print(issue)
else:
    print("\nNo brace issues detected")
