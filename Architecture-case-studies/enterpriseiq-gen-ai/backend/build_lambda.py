"""Build a deployment zip containing the handler, service and boto3 dependencies."""
from pathlib import Path
import subprocess
import sys
import tempfile
from zipfile import ZipFile, ZIP_DEFLATED


def main():
    root = Path(__file__).resolve().parents[1]
    output = root / "build" / "chat-lambda.zip"
    output.parent.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as staging:
        package = Path(staging)
        subprocess.run([
            sys.executable, "-m", "pip", "install", "--target", staging,
            "--only-binary=:all:", "--no-compile", "boto3>=1.40,<2",
        ], check=True)
        backend = package / "backend"
        backend.mkdir()
        (backend / "__init__.py").write_text("", encoding="utf-8")
        for name in ("lambda_handler.py", "rag_service.py"):
            (backend / name).write_bytes((root / "backend" / name).read_bytes())
        # Fixed timestamps and sorted entries keep unchanged builds stable.
        from zipfile import ZipInfo
        with ZipFile(output, "w", compression=ZIP_DEFLATED) as archive:
            for path in sorted(package.rglob("*")):
                if path.is_file() and "__pycache__" not in path.parts:
                    info = ZipInfo(path.relative_to(package).as_posix())
                    info.compress_type = ZIP_DEFLATED
                    archive.writestr(info, path.read_bytes())
    print(output)


if __name__ == "__main__":
    main()
