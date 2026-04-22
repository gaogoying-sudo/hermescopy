---
name: debug-embedded-js
category: software-development
description: Find and fix JavaScript syntax errors embedded in HTML files using Node.js syntax checking
tags: [debugging, javascript, html, syntax, node]
---

# Debug JavaScript Embedded in HTML

When a web page fails to load JavaScript (functions undefined, click handlers not working) and the HTML file contains inline `<script>` tags.

## Problem Pattern

- `showPage is not defined` or similar "function not defined" errors
- Click handlers on navigation links don't work
- Console shows no errors but functions are `undefined`
- All template literals appear balanced but page still broken

## Root Causes Found

1. **Backtick in regex inside template literal** — A regex like `` /`([^`]+)`/g `` breaks the template literal parser
2. **Quote conflict in inline event handlers** — `onclick="quickSend('text')"` inside a single-quoted string causes parsing failure

## Debugging Steps

### 1. Node.js Syntax Check (Most Reliable)

```python
import re, subprocess

path = 'index.html'
with open(path, 'r') as f:
    content = f.read()

# Extract JavaScript from script tags
matches = list(re.finditer(r'<script[^>]*>(.*?)</script>', content, re.DOTALL))
if len(matches) >= 2:
    js = matches[1].group(1)
    with open('/tmp/test.js', 'w') as f:
        f.write(js)
    
    result = subprocess.run(['node', '-c', '/tmp/test.js'], capture_output=True, text=True)
    print(f"Return code: {result.returncode}")
    print(f"stderr: {result.stderr}")
```

This gives the exact line and character position of syntax errors.

### 2. Backtick Count Check

```python
backticks = js.count('`')
print(f"Backticks: {backticks} (should be even)")
```

Odd backtick count = unclosed template literal.

### 3. Quote Count Check

```python
single_quotes = js.count("'")
double_quotes = js.count('"')
print(f"Single: {single_quotes} (even), Double: {double_quotes} (even)")
```

Odd counts suggest unclosed strings.

### 4. Template Literal Tracking

```python
lines = js.split('\n')
in_template = False
for i, line in enumerate(lines):
    backticks = line.count('`')
    if backticks % 2 == 1:
        in_template = not in_template
        if in_template:
            print(f"Line {i}: OPENING template: {line.strip()[:80]}")
        else:
            print(f"Line {i}: CLOSING template: {line.strip()[:80]}")
```

## Common Fixes

### Fix 1: Backtick in Regex

**Bad:**
```js
html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
```

**Good (use hex escape):**
```js
html = html.replace(/\x60([^\x60]+)\x60/g, '<code>$1</code>');
```

### Fix 2: Quote Conflict in Inline Handlers

**Bad:**
```html
<button onclick="quickSend('你好')">...</button>
```
(when inside a single-quoted JS string)

**Good (use HTML entities):**
```html
<button onclick="quickSend(&#x27;你好&#x27;)">...</button>
```

## Verification

Always run `node -c /tmp/test.js` after fixes to confirm syntax is valid before testing in browser.

## Pitfalls

1. Browser console may not show the error if the script fails to parse entirely
2. Template literal issues can cascade — fixing one may reveal another
3. The `showPage is not defined` error is a symptom, not the root cause
4. Browser caching can mask fixes — use `?nocache=123` URL param to force reload
