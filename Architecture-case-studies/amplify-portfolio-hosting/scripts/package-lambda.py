"""Reproducible Lambda ZIP; never calls AWS."""
from pathlib import Path
import zipfile
root = Path(__file__).resolve().parents[1]
output = root / "build/counter.zip"
output.parent.mkdir(parents=True, exist_ok=True)
info = zipfile.ZipInfo("handler.py", date_time=(2020, 1, 1, 0, 0, 0))
info.compress_type = zipfile.ZIP_DEFLATED
info.external_attr = 0o644 << 16
with zipfile.ZipFile(output, "w") as archive:
    archive.writestr(info, (root / "backend/counter/handler.py").read_bytes())
print("Packaged build/counter.zip")
