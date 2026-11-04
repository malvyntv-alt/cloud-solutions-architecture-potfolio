"""Write a portable Amplify archive from the Vite production output."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


def main():
    root = Path(__file__).resolve().parent
    dist = root / "dist"
    if not (dist / "index.html").is_file():
        raise SystemExit("Run the frontend build first: dist/index.html is missing.")
    artifact = root.parent / "build" / "frontend-hosting.zip"
    artifact.parent.mkdir(exist_ok=True)
    with ZipFile(artifact, "w", ZIP_DEFLATED) as archive:
        for path in sorted(dist.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(dist).as_posix())
    with ZipFile(artifact) as archive:
        assert "index.html" in archive.namelist()
        assert archive.testzip() is None
    print(f"Hosting artifact: {artifact}")


if __name__ == "__main__":
    main()
