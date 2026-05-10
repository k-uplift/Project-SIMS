"""ocr/samples/ 의 이미지들을 클라이언트인 척 /ocr/text 로 POST 한다.

[파일 명명 규칙 — 자동 검증용]
- receipt_*.{jpg,png,webp,heic,heif} → source_kind=='receipt' 기대
- object_*.{jpg,png,webp,heic,heif}  → source_kind=='object'  기대
- 기타 이름은 검증 없이 결과만 출력

[사전 준비]
- Backend/ocr/samples/ 에 위 명명 규칙대로 이미지 배치
- 별도 셸에서 uvicorn 먼저 띄워둘 것:
    cd Backend
    $env:OLLAMA_BASE_URL     = "http://119.66.214.191:31342"
    $env:OLLAMA_VISION_MODEL = "qwen2.5vl:7b"
    uvicorn ocr.main:app --reload --port 8081

[사용 예 — Backend/ 디렉터리에서]
    python -m ocr.send_sample                           # samples/ 전체 전송
    python -m ocr.send_sample --file ocr/samples/receipt_01.jpg
    python -m ocr.send_sample --server http://localhost:8081
"""
from __future__ import annotations

import argparse
import mimetypes
import sys
from pathlib import Path
from typing import Optional

import httpx


_SAMPLES_DIR = Path(__file__).resolve().parent / "samples"
_SUPPORTED_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif"}
_DEFAULT_SERVER = "http://localhost:8081"
_REQUEST_TIMEOUT = 700.0


def _iter_samples(samples_dir: Path) -> list[Path]:
    if not samples_dir.is_dir():
        return []
    return sorted(p for p in samples_dir.iterdir() if p.suffix.lower() in _SUPPORTED_EXTS)


def _expected_from_name(name: str) -> Optional[str]:
    lower = name.lower()
    if lower.startswith("receipt"):
        return "receipt"
    if lower.startswith("object"):
        return "object"
    return None


def _content_type(path: Path) -> str:
    guess, _ = mimetypes.guess_type(path.name)
    if guess:
        return guess
    return {
        ".heic": "image/heic",
        ".heif": "image/heif",
    }.get(path.suffix.lower(), "application/octet-stream")


def send_one(client: httpx.Client, server: str, image_path: Path) -> dict:
    with image_path.open("rb") as f:
        files = {"file": (image_path.name, f, _content_type(image_path))}
        resp = client.post(f"{server}/ocr/text", files=files, timeout=_REQUEST_TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def _print_result(path: Path, body: dict) -> bool:
    expected = _expected_from_name(path.name)
    kind = body.get("source_kind")
    model = body.get("model")
    text = body.get("text") or ""

    ok = True
    mark = ""
    if expected:
        ok = kind == expected
        mark = " [OK]" if ok else f" [MISS: expected {expected}]"

    print(f"{path.name}{mark}")
    print(f"  kind={kind}  model={model}")
    # TEMP DEBUG: 빈 응답 진단용 — 디버깅 끝나면 snippet으로 되돌릴 것
    print(f"  text (len={len(text)}, repr below):")
    print(f"  {text!r}")
    print()
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description="ocr 샘플을 /ocr/text 로 POST")
    parser.add_argument("--server", default=_DEFAULT_SERVER, help=f"기본 {_DEFAULT_SERVER}")
    parser.add_argument("--file", type=Path, help="단일 파일 (생략 시 samples/ 전체)")
    args = parser.parse_args()

    if args.file:
        if not args.file.is_file():
            print(f"파일 없음: {args.file}", file=sys.stderr)
            return 2
        targets = [args.file]
    else:
        targets = _iter_samples(_SAMPLES_DIR)

    if not targets:
        print(f"전송할 이미지가 없습니다. {_SAMPLES_DIR} 에 이미지를 넣어주세요.", file=sys.stderr)
        return 1

    miss = 0
    err = 0
    with httpx.Client() as client:
        for path in targets:
            try:
                body = send_one(client, args.server, path)
            except httpx.HTTPStatusError as e:
                print(f"[ERR] {path.name}: HTTP {e.response.status_code} — {e.response.text[:200]}")
                err += 1
                continue
            except httpx.HTTPError as e:
                print(f"[ERR] {path.name}: {e}")
                err += 1
                continue

            if not _print_result(path, body):
                miss += 1

    print(f"총 {len(targets)}건  분류 불일치 {miss}건  네트워크/HTTP 오류 {err}건")
    return 1 if (miss or err) else 0


if __name__ == "__main__":
    sys.exit(main())
