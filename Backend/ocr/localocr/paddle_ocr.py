"""PaddleOCR 기반 한국어 영수증 OCR.

데스크탑에서 직접 inference. Ollama·Mac Mini 미경유.
첫 호출 시 한국어 모델 자동 다운로드(~수십 MB)되며 인스턴스를 캐시해서 재사용.

PaddleOCR 3.x API 기준.
"""
from __future__ import annotations

import asyncio
import io
from functools import lru_cache

import numpy as np
from PIL import Image


@lru_cache(maxsize=1)
def _get_ocr():
    from paddleocr import PaddleOCR
    return PaddleOCR(
        lang="korean",
        use_doc_orientation_classify=False,  # EXIF orient는 preprocess에서 이미 처리
        use_doc_unwarping=False,             # 영수증은 보통 평면이라 불필요
        use_textline_orientation=True,       # 약간의 라인 회전 보정
    )


def _bytes_to_array(image_bytes: bytes) -> np.ndarray:
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    return np.array(img)


def _ocr_sync(image_bytes: bytes) -> str:
    ocr = _get_ocr()
    arr = _bytes_to_array(image_bytes)
    print(f"[paddle] input shape={arr.shape} dtype={arr.dtype}", flush=True)

    raw = ocr.predict(arr)
    # predict()는 generator일 수도 있어 list로 강제 materialize
    results = list(raw) if not isinstance(raw, list) else raw
    print(f"[paddle] results count={len(results)}", flush=True)

    lines: list[str] = []
    for i, res in enumerate(results):
        print(f"[paddle] --- result[{i}] type={type(res).__name__} ---", flush=True)
        attrs = [a for a in dir(res) if not a.startswith("_")]
        print(f"[paddle] attrs: {attrs}", flush=True)

        # 1) 직접 속성 접근 시도
        rec_texts = getattr(res, "rec_texts", None)
        if rec_texts is not None:
            print(f"[paddle] rec_texts (n={len(rec_texts)}): {rec_texts!r}", flush=True)

        # 2) json 속성 (dict 구조) 확인
        try:
            j = res.json
            print(f"[paddle] json type={type(j).__name__}", flush=True)
            if isinstance(j, dict):
                print(f"[paddle] json keys={list(j.keys())}", flush=True)
                # 흔한 중첩: json['res'] 안에 rec_texts
                if "res" in j and isinstance(j["res"], dict):
                    print(f"[paddle] json['res'] keys={list(j['res'].keys())}", flush=True)
                    if not rec_texts:
                        rec_texts = j["res"].get("rec_texts")
                        if rec_texts:
                            print(f"[paddle] used json['res']['rec_texts'] (n={len(rec_texts)})", flush=True)
                # 또는 최상위에 rec_texts
                elif "rec_texts" in j and not rec_texts:
                    rec_texts = j["rec_texts"]
                    print(f"[paddle] used json['rec_texts'] (n={len(rec_texts)})", flush=True)
        except Exception as e:
            print(f"[paddle] json access error: {type(e).__name__}: {e}", flush=True)

        if rec_texts:
            lines.extend(rec_texts)

    text = "\n".join(lines)
    print(f"[paddle] final text len={len(text)}", flush=True)
    return text


async def extract_text(image_bytes: bytes) -> str:
    """동기 PaddleOCR 호출을 thread pool로 감싸 async I/O 차단을 막는다."""
    return await asyncio.to_thread(_ocr_sync, image_bytes)
