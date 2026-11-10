"""Query Crossref for every \\bibitem of a .tex file (paced, no personal identifiers sent). Saves raw top-3 matches
to paper/refcheck/<key>.json for manual verification in paper/REFERENCES_AUDIT.md."""
import json, os, re, sys, time, urllib.parse, urllib.request
tex = open(sys.argv[1]).read()
items = re.findall(r"\\bibitem\{([^}]+)\}\s*(.*?)(?=\\bibitem|\\end\{thebibliography\})", tex, re.S)
out = sys.argv[2]
for key, txt in items:
    f = f"{out}/{key}.json"
    if os.path.exists(f):
        continue
    q = re.sub(r"[\\{}$]|\\textbf|\\emph|\\url", " ", txt)
    q = re.sub(r"\s+", " ", q).strip()[:300]
    url = "https://api.crossref.org/works?rows=3&select=DOI,title,author,container-title,issued,volume,page&query.bibliographic=" + urllib.parse.quote(q)
    for attempt in range(4):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "jsc-revision-refcheck/1.0"})
            data = json.load(urllib.request.urlopen(req, timeout=30))
            break
        except Exception as e:
            time.sleep(10 * (attempt + 1)); data = {"error": str(e)}
    items_ = data.get("message", {}).get("items", []) if "message" in data else []
    json.dump(dict(key=key, query=q, matches=items_, error=data.get("error")), open(f, "w"), indent=1)
    best = items_[0] if items_ else {}
    print(f"{key:28s} -> {best.get('DOI')} | {(best.get('title') or [''])[0][:70]} | {(best.get('container-title') or [''])[0][:40]} | {best.get('issued',{}).get('date-parts',[[None]])[0][0]}", flush=True)
    time.sleep(3)
