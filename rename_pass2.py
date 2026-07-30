"""Second pass: catch remaining AIR references."""
import os, re

BASE = r"C:\Users\mahes\OneDrive\Desktop\GARAGE_CODE\raix"

files = []
for root, dirs, fs in os.walk(BASE):
    dirs[:] = [d for d in dirs if d != '.git']
    for f in fs:
        if f.endswith(('.R', '.Rd', '.md', '.yml', '.yaml')) or f in ('DESCRIPTION', 'NAMESPACE'):
            files.append(os.path.join(root, f))

for fp in files:
    with open(fp, 'r', encoding='utf-8', errors='replace') as fh:
        content = fh.read()
    orig = content

    # Simple string replacements for common patterns
    replacements = [
        # Shiny app
        ('"Message AIR...', '"Message raix...'),
        ('"AIR Chat"', '"raix Chat"'),
        # README
        ('AIR>', 'raix>'),
        # testthat
        ('test_check("air")', 'test_check("raix")'),
        ("test_check('air')", "test_check('raix')"),
        # backends error messages
        ('"AIR: cannot parse response', '"raix: cannot parse response'),
        ('"AIR: bad response structure', '"raix: bad response structure'),
        ("AIR: missing '", "raix: missing '"),
        ('"AIR: empty response', '"raix: empty response'),
        # comment
        ('in air.R ---', 'in raix.R ---'),
        # utils strings
        ('Welcome to AIR ---', 'Welcome to raix ---'),
        ('use AIR ---', 'use raix ---'),
        ('Opening AIR cheat sheet', 'Opening raix cheat sheet'),
        ('<h2>AIR --- AI for R</h2>', '<h2>raix --- AI for R</h2>'),
        ('Opening AIR setup script', 'Opening raix setup script'),
        # RStudio options
        ('getOption("air.', 'getOption("raix.'),
        ("getOption('air.", "getOption('raix."),
        ('options("air.', 'options("raix.'),
        ("options('air.", "options('raix."),
    ]
    
    for old, new in replacements:
        content = content.replace(old, new)

    # Any remaining "AIR" at start of sentence in comments/strings
    # that wasn't caught above
    content = content.replace('"AIR ', '"raix ')
    content = content.replace("'AIR ", "'raix ")
    
    if content != orig:
        print(f"  FIXED: {os.path.relpath(fp, BASE)}")
        with open(fp, 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(content)

print("Second pass complete")
