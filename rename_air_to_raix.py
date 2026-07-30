"""Rename all 'air' references to 'raix' throughout the codebase.

Rules (in order of application to avoid double-replacement):
1. Function definitions: air_xxx <- function → raix_xxx <- function
2. Function calls: air_xxx( → raix_xxx(
3. Internal vars: air_env → raix_env, air_detect_format → raix_detect_format
4. Internal backend fns: air_openai_compatible, air_ollama_native, air_claude_native, air_api_call
5. String literals: "AIR ..." → "raix ...", 'AIR ...' → 'raix ...'
6. RStudio options: air.provider → raix.provider, air.model → raix.model
7. Comment references: # AIR → # raix
8. File names: air.R → raix.R, air_*.Rd → raix_*.Rd

IMPORTANT: NOT replacing 'air' when it's part of another word (pair, repair, etc.)
or when it's part of 'raix' itself (already correct).
"""
import os
import re
import shutil

BASE = r"C:\Users\mahes\OneDrive\Desktop\GARAGE_CODE\raix"

# Files to process
text_files = []
for root, dirs, files in os.walk(BASE):
    # Skip .git
    dirs[:] = [d for d in dirs if d != '.git']
    for f in files:
        if f.endswith(('.R', '.Rd', '.md', '.yml', '.yaml')) or f in ('DESCRIPTION', 'NAMESPACE'):
            text_files.append(os.path.join(root, f))

print(f"Found {len(text_files)} files to process")

for filepath in text_files:
    with open(filepath, 'r', encoding='utf-8', errors='replace') as fh:
        content = fh.read()
    
    original = content
    
    # Order matters: most specific replacements first
    
    # 1. Internal backend functions (most specific)
    content = content.replace('air_openai_compatible', 'raix_openai_compatible')
    content = content.replace('air_ollama_native', 'raix_ollama_native')
    content = content.replace('air_claude_native', 'raix_claude_native')
    content = content.replace('air_api_call', 'raix_api_call')
    content = content.replace('air_detect_format', 'raix_detect_format')
    
    # 2. RStudio addin
    content = content.replace('air_addin_chat', 'raix_addin_chat')
    
    # 3. Internal environment state
    content = content.replace('air_env', 'raix_env')
    
    # 4. RStudio options (before function names, more specific)
    content = content.replace('air.provider', 'raix.provider')
    content = content.replace('air.model', 'raix.model')
    
    # 5. Function definitions: air_xxx <- function
    # Already handled by air_xxx replacement below
    
    # 6. Exported functions: air_configure, air_send, etc. (17 functions)
    funcs = ['air_configure', 'air_send', 'air_explain', 'air_debug', 
             'air_document', 'air_generate', 'air_chat', 'air_info',
             'air_check', 'air_setup', 'air_search', 'air_diagnose',
             'air_analyze', 'air_google', 'air_rstudio', 'air_help', 'air_gui']
    for fn in funcs:
        raix_fn = fn.replace('air_', 'raix_')
        content = content.replace(fn, raix_fn)
    
    # 7. String literals with "AIR " or "AIR-" or "AIR\n" etc.
    #    But NOT "raix" which is already correct
    content = re.sub(r'(?<!")(?<!raix)(")AIR ', r'\1raix ', content)
    content = re.sub(r"(?<!')(?<!raix)(')AIR ", r"\1raix ", content)
    
    # 8. Comment lines: # AIR → # raix
    content = re.sub(r'^(\s*#\s*)AIR\b', r'\1raix', content, flags=re.MULTILINE)
    
    # 9. Standalone AIR in prose/comments (word boundary)
    # Only in comments and strings, not in code identifiers
    lines = content.split('\n')
    new_lines = []
    for line in lines:
        stripped = line.strip()
        # In comments
        if stripped.startswith('#'):
            # Replace "AIR" as a standalone word but not part of "raix"
            line = re.sub(r'\bAIR\b(?!\w)', 'raix', line)
        new_lines.append(line)
    content = '\n'.join(new_lines)
    
    if content != original:
        print(f"  MODIFIED: {os.path.relpath(filepath, BASE)}")
        with open(filepath, 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(content)

# Rename files
print("\nRenaming files...")
renames = [
    ('R/air.R', 'R/raix.R'),
]
for old, new in renames:
    old_path = os.path.join(BASE, old)
    new_path = os.path.join(BASE, new)
    if os.path.exists(old_path):
        os.rename(old_path, new_path)
        print(f"  {old} → {new}")

# Rename man pages
man_dir = os.path.join(BASE, 'man')
for f in os.listdir(man_dir):
    if f.startswith('air_') and f.endswith('.Rd'):
        old_path = os.path.join(man_dir, f)
        new_path = os.path.join(man_dir, f.replace('air_', 'raix_'))
        os.rename(old_path, new_path)
        print(f"  man/{f} → man/{f.replace('air_', 'raix_')}")

print("\nDone!")
