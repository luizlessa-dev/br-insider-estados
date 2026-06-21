#!/usr/bin/env python3
"""
Probe de assinatura Implanta / PortalTransparencia.Net em portais de conselhos de classe.
Para cada host candidato, testa o endpoint OpenAPI:  {scheme}://{host}{base}/transparencia/api/swagger/docs/v1
Confirma se HTTP 200 + JSON swagger (com 'paths'). Conta endpoints.

Uso:
  echo "host1\nhost2" | python3 probe_implanta.py
  python3 probe_implanta.py hosts.txt
Saída: JSONL no stdout (um objeto por host testado, só os que respondem algo relevante por padrão --all mostra tudo).
"""
import sys, json, ssl, urllib.request, urllib.error, socket, concurrent.futures

socket.setdefaulttimeout(18)
CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"

# caminhos candidatos para o swagger, relativos ao host
SWAGGER_PATHS = [
    "/transparencia/api/swagger/docs/v1",
    "/api/swagger/docs/v1",
    "/portaltransparencia/api/swagger/docs/v1",
]

def fetch(url, timeout=18):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json,*/*"})
    try:
        with urllib.request.urlopen(req, context=CTX, timeout=timeout) as r:
            body = r.read(4_000_000)
            return r.status, r.headers.get_content_type(), body
    except urllib.error.HTTPError as e:
        return e.code, None, None
    except Exception as e:
        return None, str(e), None

def probe_host(host):
    host = host.strip().rstrip("/")
    if not host or host.startswith("#"):
        return None
    # aceita host nu ou com esquema
    if host.startswith("http://") or host.startswith("https://"):
        bases = [host]
    else:
        bases = [f"https://{host}"]
    result = {"host": host, "hit": False}
    for base in bases:
        for p in SWAGGER_PATHS:
            url = base + p
            status, ctype, body = fetch(url)
            if status == 200 and body:
                try:
                    d = json.loads(body)
                    if isinstance(d, dict) and "paths" in d:
                        paths = list(d.get("paths", {}).keys())
                        result.update({
                            "hit": True,
                            "spec_url": url,
                            "n_endpoints": len(paths),
                            "endpoints": [x.replace("/v1.0/", "") for x in paths],
                            "title": d.get("info", {}).get("title"),
                        })
                        return result
                except Exception:
                    pass
            if status:
                result.setdefault("tried", []).append({"url": url, "status": status})
    return result

def main():
    if len(sys.argv) > 1 and sys.argv[1] not in ("-", "--all"):
        hosts = open(sys.argv[1]).read().splitlines()
    else:
        hosts = sys.stdin.read().splitlines()
    hosts = [h for h in (x.strip() for x in hosts) if h and not h.startswith("#")]
    show_all = "--all" in sys.argv
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as ex:
        for r in ex.map(probe_host, hosts):
            if r is None:
                continue
            if r["hit"] or show_all:
                print(json.dumps(r, ensure_ascii=False), flush=True)

if __name__ == "__main__":
    main()
