"""Check local Markdown links and tracked public-artifact boundaries."""
from pathlib import Path
import re
import subprocess
root = Path(__file__).resolve().parents[1]
errors = []
for doc in root.rglob("*.md"):
    if any(p in {".git", ".terraform", ".venv", "__pycache__"} for p in doc.parts): continue
    for link in re.findall(r"\]\(([^)]+)\)", doc.read_text(encoding="utf-8")):
        target = link.split("#", 1)[0].strip("<>")
        if target and "://" not in target and not target.startswith("mailto:") and not (doc.parent / target).exists():
            errors.append(f"Broken link: {doc.relative_to(root)} -> {target}")
for name in subprocess.check_output(["git", "-C", str(root), "ls-files", "-z"]).decode().split("\0"):
    if not name: continue
    p = Path(name)
    if (".terraform" in p.parts or ".tfstate" in p.name or p.suffix == ".tfplan"
        or "data" in p.parts or p.name == "backend.hcl" or p.name.startswith(".env")
        or p.name.endswith((".tfvars", ".tfvars.json", ".pem", ".key"))):
        errors.append(f"Private artifact tracked: {name}")
if errors: raise SystemExit("\n".join(errors))
print("Repository links and tracked artifact boundaries passed.")
