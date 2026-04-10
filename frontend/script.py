import os
import re

# Carpeta raíz de tu proyecto Flutter
ROOT_DIR = "frontend/lib"

# Expresiones regulares para encontrar URLs antiguas
URL_PATTERN = re.compile(r'''["'](http://10\.0\.2\.2:8000/[\w/]+)["']''')

# Activar dry run para solo mostrar cambios
DRY_RUN = False

def replace_urls_in_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    matches = URL_PATTERN.findall(content)
    if not matches:
        return

    new_content = content
    for url in matches:
        path = url.replace("http://10.0.2.2:8000/", "")
        replacement = f'ApiConfig.endpoint("{path}")'
        new_content = new_content.replace(f'"{url}"', replacement)
        new_content = new_content.replace(f"'{url}'", replacement)

        if DRY_RUN:
            print(f"[DRY RUN] {file_path}: {url} → {replacement}")

    if not DRY_RUN:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Reemplazado en: {file_path}")

def walk_dir(root_dir):
    for root, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".dart"):
                replace_urls_in_file(os.path.join(root, file))

if __name__ == "__main__":
    walk_dir(ROOT_DIR)
    print("✅ Revisión completa (modo dry run)")

