import os
import glob
import base64
import zlib
import urllib.request
import time

def encode_kroki(text):
    compressed = zlib.compress(text.encode('utf-8'), 9)
    return base64.urlsafe_b64encode(compressed).decode('utf-8')

def process_file(filepath):
    print(f"Processing: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract just the mermaid code
    if '```mermaid' in content:
        mermaid_code = content.split('```mermaid')[1].split('```')[0].strip()
    else:
        mermaid_code = content.strip()
    
    # Kroki URL
    payload = encode_kroki(mermaid_code)
    url = f"https://kroki.io/mermaid/svg/{payload}"
    
    # Destination PNG
    dest_path = filepath.replace(".md", ".svg")
    
    try:
        # Download from Kroki
        # SVG is often better quality for diagrams, let's use SVG. The user said "diagrams not .md files". SVGs are widely supported.
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open(dest_path, 'wb') as out_file:
            out_file.write(response.read())
        print(f"Successfully generated {dest_path}")
        
        # Remove the original .md file if successful
        os.remove(filepath)
        print(f"Removed original markdown file: {filepath}")
        
    except Exception as e:
        print(f"Failed to generate diagram for {filepath}: {e}")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    md_files = glob.glob(os.path.join(script_dir, "*.md"))
    
    if not md_files:
        print("No .md files found in the diagrams folder.")
        
    for md_file in md_files:
        process_file(md_file)
        time.sleep(1) # Be polite to the public API
        
    print("Done!")
