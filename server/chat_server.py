#!/usr/bin/env python3
"""Realtime chat untuk portofolio Noval. Stdlib only. Bind 0.0.0.0:8765"""
from __future__ import annotations

import json
import re
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import os
import mimetypes

HOST, PORT = "0.0.0.0", int(os.environ.get("CHAT_PORT", "8765"))
ROOT = Path(__file__).resolve().parent.parent
SERVE_STATIC = os.environ.get("SERVE_STATIC", "0") == "1"
DATA = Path(__file__).resolve().parent.parent / "data" / "chat.json"
LOCK = threading.Lock()
TYPING_UNTIL = 0.0

WELCOME = {
    "id": 1,
    "name": "Noval",
    "text": "Halo! Saya Noval Rizki, siswa kelas 11 PPLG SMK Al Madani Garut. Chat ini realtime — kirim pesan, saya balas.",
    "ts": time.time(),
}


def load() -> list:
    DATA.parent.mkdir(parents=True, exist_ok=True)
    if not DATA.exists():
        DATA.write_text(json.dumps([WELCOME]), encoding="utf-8")
    try:
        return json.loads(DATA.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return [WELCOME]


def save(msgs: list) -> None:
    DATA.write_text(json.dumps(msgs[-400:], ensure_ascii=False), encoding="utf-8")


def reply_text(text: str) -> str:
    t = text.lower()
    rules = [
        (r"halo|hai|hi|assalam", "Halo! Saya Noval. Senang bisa ngobrol realtime di sini."),
        (r"sekolah|smk|madani", "Saya sekolah di SMK Al Madani Garut."),
        (r"kelas|11|pplg", "Kelas 11 PPLG — Pengembangan Perangkat Lunak dan Gim."),
        (r"garut", "Betul, Garut. Tempat saya belajar dan bikin proyek."),
        (r"web|html|css|js", "Saya suka merancang web yang rapi, cepat, dan punya karakter."),
        (r"nama", "Noval Rizki."),
        (r"kontak|email", "Bisa lewat halaman Kontak atau langsung chat di sini."),
        (r"proyek|karya|porto", "Lihat halaman Karya — situs ini sendiri di-host di VPS dengan SSL."),
    ]
    for pat, ans in rules:
        if re.search(pat, t):
            return ans
    return "Siap. Saya Noval, 11 PPLG SMK Al Madani Garut. Tanya saja soal sekolah, skill, atau proyek."


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        if SERVE_STATIC and not parsed.path.startswith("/api"):
            self._static(parsed.path)
            return
        if parsed.path not in ("/api/chat", "/chat"):
            self.send_response(404)
            self.end_headers()
            return
        qs = parse_qs(parsed.query)
        since = int(qs.get("since", ["0"])[0] or 0)
        with LOCK:
            msgs = [m for m in load() if m.get("id", 0) > since]
            typing = time.time() < TYPING_UNTIL
        body = json.dumps({"messages": msgs, "typing": typing}).encode()
        self.send_response(200)
        self._cors()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        global TYPING_UNTIL
        parsed = urlparse(self.path)
        if parsed.path not in ("/api/chat", "/chat"):
            self.send_response(404)
            self.end_headers()
            return
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length else b"{}"
        try:
            payload = json.loads(raw.decode() or "{}")
        except json.JSONDecodeError:
            payload = {}
        name = str(payload.get("name") or "Tamu")[:40]
        text = str(payload.get("text") or "").strip()[:800]
        if not text:
            self.send_response(400)
            self.end_headers()
            return
        with LOCK:
            msgs = load()
            nid = (msgs[-1]["id"] if msgs else 0) + 1
            user_msg = {"id": nid, "name": name, "text": text, "ts": time.time()}
            msgs.append(user_msg)
            save(msgs)
        TYPING_UNTIL = time.time() + 1.4

        def later():
            time.sleep(0.9)
            global TYPING_UNTIL
            with LOCK:
                msgs2 = load()
                rid = (msgs2[-1]["id"] if msgs2 else 0) + 1
                msgs2.append(
                    {
                        "id": rid,
                        "name": "Noval",
                        "text": reply_text(text),
                        "ts": time.time(),
                    }
                )
                save(msgs2)
            TYPING_UNTIL = 0

        threading.Thread(target=later, daemon=True).start()
        body = json.dumps({"ok": True, "message": user_msg}).encode()
        self.send_response(200)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


    def _static(self, path):
        if path in ("", "/"):
            path = "/index.html"
        rel = path.lstrip("/")
        file = (ROOT / rel).resolve()
        if ROOT.resolve() not in file.parents and file != ROOT.resolve():
            self.send_response(403)
            self.end_headers()
            return
        if not file.is_file():
            self.send_response(404)
            self.end_headers()
            return
        ctype = mimetypes.guess_type(str(file))[0] or "application/octet-stream"
        data = file.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

def main():
    DATA.parent.mkdir(parents=True, exist_ok=True)
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"chat listening on {HOST}:{PORT}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
