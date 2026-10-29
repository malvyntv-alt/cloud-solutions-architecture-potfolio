"""Check portfolio Markdown links and publishable tracked files."""
from pathlib import Path
import re
import subprocess
root = Path(__file__).resolve().parents[1]
errors = []
for doc in root.rglob("*.md"):
    if any(p in {".git", ".venv", ".terraform", "__pycache__"} for p in doc.parts):
        continue
    for link in re.findall(r"\]\(([^)]+)\)", doc.read_text(encoding="utf-8")):
        target = link.split("#", 1)[0].strip("<>")
        if target and "://" not in target and not target.startswith("mailto:") and not (doc.parent / target).exists():
            errors.append(f"Broken link: {doc.relative_to(root)} -> {target}")
names = subprocess.check_output(["git", "-C", str(root), "ls-files", "-z"]).decode().split("\0")
for name in filter(None, names):
    p = Path(name)
    private = (any(v in p.parts for v in (".git", ".venv", ".terraform", "__pycache__", "data", "raw"))
               or ".tfstate" in p.name or p.name == "backend.hcl" or p.name.startswith(".env")
               or p.name.endswith((".tfvars", ".tfvars.json", ".tfplan", ".log", ".pem", ".key")))
    if private:
        errors.append(f"Private/generated artifact tracked: {name}")
if (root / ".gitmodules").exists():
    errors.append("Nested projects must be ordinary folders, not submodules.")
for project in (root / "Architecture-case-studies").iterdir():
    if project.is_dir() and (project / ".git").exists():
        errors.append(f"Nested Git repository: {project.name}")
if errors:
    raise SystemExit("\n".join(errors))
print("Portfolio links, project layout and tracked artifact boundaries passed.")
