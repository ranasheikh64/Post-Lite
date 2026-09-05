import os
import re

lib_dir = 'lib'

snackbar_pattern = re.compile(r"Get\.snackbar\(\s*'([^']+)'\s*,\s*(.*?)\s*\)")

def replace_snackbar(match):
    title = match.group(1)
    message = match.group(2)
    # Check if title indicates an error
    is_error = 'true' if 'error' in title.lower() or 'failed' in title.lower() else 'false'
    if is_error == 'true':
        return f"CustomSnackbar.show(title: '{title}', message: {message}, isError: true)"
    else:
        return f"CustomSnackbar.show(title: '{title}', message: {message})"

def add_import_if_missing(content, import_statement):
    if import_statement not in content:
        # Find the last import
        import_match = list(re.finditer(r"^import\s+.*?;$", content, re.MULTILINE))
        if import_match:
            last_import = import_match[-1]
            insertion_point = last_import.end()
            return content[:insertion_point] + "\n" + import_statement + content[insertion_point:]
        else:
            return import_statement + "\n" + content
    return content

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Replace Get.snackbar
            if 'Get.snackbar' in content:
                content = snackbar_pattern.sub(replace_snackbar, content)
                content = add_import_if_missing(content, "import 'package:postmanclone/app/widgets/custom_snackbar.dart';")
            
            # Replace loaders
            # Pattern 1: Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
            loader_pattern = re.compile(r"Get\.dialog\(\s*const Center\(child:\s*CircularProgressIndicator\(\)\),\s*barrierDismissible:\s*false,?\s*\);")
            if loader_pattern.search(content):
                content = loader_pattern.sub("CustomLoader.show();", content)
                content = add_import_if_missing(content, "import 'package:postmanclone/app/widgets/custom_loader.dart';")
                
            loader_hide_pattern = re.compile(r"Get\.back\(\);\s*//\s*close loader")
            if loader_hide_pattern.search(content):
                content = loader_hide_pattern.sub("CustomLoader.hide();", content)
            
            if content != original_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Updated {filepath}")
