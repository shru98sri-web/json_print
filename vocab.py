import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

JSON_FILE = Path(__file__).parent / "vocab_250.json"
HOST, PORT = "0.0.0.0", 8000      # 0.0.0.0 lets a real phone on your Wi-Fi connect too


def load_words():
    data = json.loads(JSON_FILE.read_text(encoding="utf-8"))
    raw = data["words"] if isinstance(data, dict) else data

    seen, words = set(), []
    for w in raw:
        wid = w.get("id")
        if wid in seen:                     # your file has id 100 twice
            continue
        seen.add(wid)
        pos = str(w.get("part_of_speech", ""))
        if len(pos) > 30:                   # e.g. id 44 has a sentence in this field
            w["part_of_speech"] = "unknown"
        words.append(w)
    return data.get("metadata", {}) if isinstance(data, dict) else {}, words


META, WORDS = load_words()


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")   # needed for Flutter web
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def do_GET(self):
        url = urlparse(self.path)
        q = parse_qs(url.query)

        if url.path == "/health":
            return self._send(200, {"status": "ok", "count": len(WORDS)})

        if url.path == "/words":
            items = WORDS
            if "letter" in q:
                items = [w for w in items if w.get("letter", "").upper() == q["letter"][0].upper()]
            if "q" in q:
                s = q["q"][0].lower()
                items = [w for w in items if s in w.get("word", "").lower()
                         or s in w.get("meaning", "").lower()]
            total = len(items)
            offset = int(q.get("offset", [0])[0])
            limit = int(q.get("limit", [len(items) or 1])[0])
            return self._send(200, {
                "metadata": META,
                "total": total,
                "words": items[offset: offset + limit],
            })

        self._send(404, {"error": "Not found"})

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


if __name__ == "__main__":
    print(f"Serving {len(WORDS)} words at http://localhost:{PORT}/words")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()