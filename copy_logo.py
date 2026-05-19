import shutil
import os

src = r'C:\Users\joelj\.gemini\antigravity\brain\88e7c9f4-6abb-4fce-a790-ed948d071f09\ai_ktu_launcher_logo_1774200303921.png'
dst = r'c:\projects\Projects\mini\ai_ktu_notes_app\assets\images\app_logo.png'

print(f"Copying from {src} to {dst}")
if os.path.exists(src):
    shutil.copy2(src, dst)
    print("Copy successful")
else:
    print("Source file missing")

print("Contents of assets/images:", os.listdir(r'c:\projects\Projects\mini\ai_ktu_notes_app\assets\images'))
