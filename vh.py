#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
vh.py - Cong cu Viet hoa Pathfinder: Kingmaker (enGB -> vnVN)
Mo hinh Translation Memory (TM): dich theo NOI DUNG tieng Anh de tu dong
khu trung lap va dam bao nhat quan xuyen suot.

Subcommands:
  index            Quet toan bo file enGB, dung index cac chuoi duy nhat.
  next [N]         Lay N chuoi chua dich tiep theo -> batch_in.json
  merge            Gop batch_out.json vao tm.json (co kiem tra tag).
  build            Sinh/ cap nhat cac file vnVN tu enGB + tm.json.
  stats            Bao cao tien do.
  validate         Kiem tra lai toan bo tag parity trong tm.json.
"""
import os, sys, json, glob, re, io, shutil

BASE = os.path.dirname(os.path.abspath(__file__))          # ..._viethoa
LOC  = os.path.dirname(BASE)                                # Localization
TM_PATH      = os.path.join(BASE, "tm.json")
PACK_PATH    = os.path.join(BASE, "vnVN_pack.json")   # goi guid->text (FULL: da dich=Viet, chua=English) cho mod UMM KingmakerVN
INDEX_PATH   = os.path.join(BASE, "index.json")
BATCH_IN     = os.path.join(BASE, "batch_in.json")
BATCH_OUT    = os.path.join(BASE, "batch_out.json")
REJECTS      = os.path.join(BASE, "batch_rejects.json")
MAIN_FILE    = "enGB.json"
SRC_PREFIX   = "enGB"
DST_PREFIX   = "ruRU"   # (chi dung khi 'buildfiles' - ghi de file). Cach moi = mod KingmakerVN inject pack vao khe ruRU luc chay, KHONG ghi de file goc.

# --- Tag duoc coi la cau truc, phai giu nguyen so luong giua EN va VI ---
CRITICAL_TAGS = ["{mf|", "{g|", "{/g}", "{d|", "{n|", "{name|",
                 "<b>", "</b>", "<i>", "</i>", "<color", "</color>",
                 "<size", "</size>"]

def read_json(path):
    with io.open(path, "r", encoding="utf-8-sig") as f:
        return json.load(f)

def write_json(path, obj, indent=2):
    # Ghi kieu nguyen-tu: ghi ra file .tmp roi os.replace. Neu hong giua chung
    # (mat dien, crash) thi file goc van nguyen ven, khong bi cut/hong.
    tmp = path + ".tmp"
    with io.open(tmp, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=indent)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)   # nguyen-tu tren cung o dia (ca Windows)

def load_tm():
    if os.path.exists(TM_PATH):
        return read_json(TM_PATH)
    return {}

def src_files():
    files = sorted(glob.glob(os.path.join(LOC, SRC_PREFIX + "*.json")))
    return files

def count_tags(s):
    return {t: s.count(t) for t in CRITICAL_TAGS}

def tag_mismatch(en, vi):
    """Tra ve list mo ta cac tag khong khop (rong = OK)."""
    ce, cv = count_tags(en), count_tags(vi)
    issues = []
    for t in CRITICAL_TAGS:
        if ce[t] != cv[t]:
            issues.append("%s en=%d vi=%d" % (t, ce[t], cv[t]))
    # can bang ngoac nhon
    if en.count("{") - en.count("}") != vi.count("{") - vi.count("}"):
        issues.append("brace-balance")
    return issues

# ---------------------------------------------------------------- index
def cmd_index():
    files = src_files()
    main_vals = set()
    freq = {}        # en -> count occurrences
    for fp in files:
        j = read_json(fp)
        is_main = os.path.basename(fp) == MAIN_FILE
        for s in j.get("strings", []):
            v = s.get("Value", "")
            if v is None or v.strip() == "":
                continue
            freq[v] = freq.get(v, 0) + 1
            if is_main:
                main_vals.add(v)
    idx = {
        "total_files": len(files),
        "unique": len(freq),
        "in_main": len(main_vals),
        "freq": freq,
        "main": sorted(main_vals),
    }
    write_json(INDEX_PATH, idx)
    print("[index] files=%d unique=%d in_main=%d" %
          (len(files), len(freq), len(main_vals)))

def ensure_index():
    if not os.path.exists(INDEX_PATH):
        cmd_index()
    return read_json(INDEX_PATH)

# ---------------------------------------------------------------- next
def cmd_next(n=150):
    idx = ensure_index()
    tm = load_tm()
    freq = idx["freq"]
    main = set(idx["main"])
    pending = [en for en in freq.keys() if en not in tm]
    # Uu tien: trong file UI chinh truoc, roi tan suat cao, roi ngan truoc
    def sortkey(en):
        return (0 if en in main else 1, -freq[en], len(en), en)
    pending.sort(key=sortkey)
    batch = [{"i": k, "en": en} for k, en in enumerate(pending[:n])]
    write_json(BATCH_IN, batch)
    print("[next] pending_total=%d  batch=%d -> %s" %
          (len(pending), len(batch), BATCH_IN))
    if batch:
        nmain = sum(1 for b in batch if b["en"] in main)
        print("       (trong batch: %d thuoc UI chinh)" % nmain)

# ---------------------------------------------------------------- merge
def cmd_merge():
    if not os.path.exists(BATCH_OUT):
        print("[merge] khong thay batch_out.json"); return
    try:
        bin_ = read_json(BATCH_IN)
    except Exception as e:
        print("[merge] LOI doc batch_in.json: %s -> bo qua, khong dong gi." % e); return
    try:
        bout = read_json(BATCH_OUT)
    except Exception as e:
        print("[merge] LOI doc batch_out.json (hong / khong phai JSON hop le): %s" % e)
        print("        -> KHONG merge, KHONG dong gi. Sua batch_out.json roi merge lai, hoac dich lai me nay.")
        return
    if isinstance(bout, list):
        if len(bout) == 0:
            print("[merge] batch_out rong, khong co gi de merge."); return
        print("[merge] batch_out sai dinh dang (can object {\"i\": \"vi\"}, gap list)."); return
    if not isinstance(bout, dict):
        print("[merge] batch_out sai dinh dang (can object {\"i\": \"vi\"})."); return
    en_by_i = {b["i"]: b["en"] for b in bin_}
    tm = load_tm()
    # Backup tm.json truoc khi ghi de -> co the khoi phuc 1 buoc neu hong.
    if os.path.exists(TM_PATH):
        try: shutil.copy2(TM_PATH, TM_PATH + ".bak")
        except Exception: pass
    ok = 0; rejects = []
    for k, vi in bout.items():
        try:
            i = int(k)
        except (ValueError, TypeError):
            rejects.append({"i": k, "reason": "key khong phai so", "vi": vi})
            continue
        en = en_by_i.get(i)
        if en is None:
            rejects.append({"i": i, "reason": "id khong co trong batch_in", "vi": vi})
            continue
        if vi is None or vi == "":
            rejects.append({"i": i, "en": en, "reason": "vi rong"})
            continue
        issues = tag_mismatch(en, vi)
        if issues:
            rejects.append({"i": i, "en": en, "vi": vi, "reason": "tag: " + "; ".join(issues)})
            continue
        tm[en] = vi
        ok += 1
    write_json(TM_PATH, tm)
    write_json(REJECTS, rejects)
    # LUON xoa batch_out sau merge: da nhan -> tm.json, bi tu choi -> batch_rejects.json (giu en goc).
    # Tranh du lieu me cu con sot lai, lan sau index 'i' danh lai tu 0 se gan nham vi vao en khac.
    write_json(BATCH_OUT, [])
    print("[merge] nhan=%d  tu_choi=%d  tm_total=%d" % (ok, len(rejects), len(tm)))
    if ok == 0 and rejects and all(str(r.get("reason", "")).startswith("id khong") for r in rejects):
        print("        !! CANH BAO: batch_out co ve la DU LIEU ME CU (index 'i' khong khop batch_in). Khong co chuoi nao duoc nhan.")
    if rejects:
        print("        -> xem batch_rejects.json (giu en goc) de dich lai o me ke tiep")

# ---------------------------------------------------------------- build (mod mode - MAC DINH)
def cmd_build(only_complete=False):
    """Cach moi (mod UMM): KHONG ghi de file locale. Chi bao tien do + sinh
    vnVN_pack.json (full). Mod KingmakerVN tu doc pack va phu len khe ruRU luc chay.
    Muon quay lai kieu ghi de file: dung 'python vh.py buildfiles'."""
    tm = load_tm()
    total = 0; trans = 0
    for fp in src_files():
        for s in read_json(fp).get("strings", []):
            v = s.get("Value", "")
            if v is None or v.strip() == "":
                continue
            total += 1
            if v in tm:
                trans += 1
    print("[build] (che do mod) %d/%d chuoi instance da dich. KHONG ghi de file locale." % (trans, total))
    cmd_pack()

# ---------------------------------------------------------------- buildfiles (kieu cu: GHI DE file ruRU)
def cmd_build_files(only_complete=False):
    tm = load_tm()
    files = src_files()
    written = 0; full = 0
    for fp in files:
        j = read_json(fp)
        total = 0; trans = 0
        for s in j.get("strings", []):
            v = s.get("Value", "")
            if v is None or v.strip() == "":
                continue
            total += 1
            if v in tm:
                trans += 1
        if only_complete and trans < total:
            continue
        # sinh file vnVN
        for s in j.get("strings", []):
            v = s.get("Value", "")
            if v is not None and v.strip() != "" and v in tm:
                s["Value"] = tm[v]
        dst = os.path.join(LOC, DST_PREFIX + os.path.basename(fp)[len(SRC_PREFIX):])
        write_json(dst, j)
        written += 1
        if total == 0 or trans == total:
            full += 1
    print("[build] da ghi %d file vnVN (%d file dich day du)." % (written, full))
    cmd_pack()

# ---------------------------------------------------------------- pack (cho mod UMM)
def cmd_pack():
    """Xuat vnVN_pack.json = { guid: text } cho MOI chuoi (da dich = tieng Viet,
    chua dich = English fallback). Mod UMM KingmakerVN doc file nay roi AppendPack
    de phu len khe ruRU luc chay -> KHONG ghi de file goc; chuoi chua dich hien English
    (khong bi lot tieng Nga goc)."""
    tm = load_tm()
    pack = {}
    for fp in src_files():
        for s in read_json(fp).get("strings", []):
            en = s.get("Value", "")
            key = s.get("Key", "")
            if not key or en is None or en.strip() == "":
                continue
            pack[key] = tm.get(en, en)   # da dich -> Viet; chua -> English
    write_json(PACK_PATH, pack)
    print("[pack] da ghi %d chuoi (full, fallback English) -> %s" % (len(pack), os.path.basename(PACK_PATH)))

# ---------------------------------------------------------------- stats
def cmd_stats():
    idx = ensure_index()
    tm = load_tm()
    freq = idx["freq"]
    uniq = len(freq)
    done = sum(1 for en in freq if en in tm)
    # tinh theo so lan xuat hien (do phu thuc te)
    occ_total = sum(freq.values())
    occ_done  = sum(c for en, c in freq.items() if en in tm)
    ch_total = sum(len(en) for en in freq)
    ch_done  = sum(len(en) for en in freq if en in tm)
    def pct(a, b): return (100.0*a/b) if b else 0.0
    print("=== TIEN DO VIET HOA ===")
    print("Chuoi duy nhat : %d/%d  (%.2f%%)" % (done, uniq, pct(done, uniq)))
    print("Theo lan dung  : %d/%d  (%.2f%%)" % (occ_done, occ_total, pct(occ_done, occ_total)))
    print("Theo ky tu     : %d/%d  (%.2f%%)" % (ch_done, ch_total, pct(ch_done, ch_total)))

# ---------------------------------------------------------------- pending
def cmd_pending():
    """In DUY NHAT so chuoi duy nhat con lai chua dich (cho script vong lap doc).
    Exit code 0 neu con viec, 1 neu da xong het (de '&&' trong shell tu dung)."""
    idx = ensure_index()
    tm = load_tm()
    n = sum(1 for en in idx["freq"] if en not in tm)
    print(n)
    return n

def main():
    args = sys.argv[1:]
    cmd = args[0] if args else "stats"
    if cmd == "index":   cmd_index()
    elif cmd == "next":  cmd_next(int(args[1]) if len(args) > 1 else 150)
    elif cmd == "merge": cmd_merge()
    elif cmd == "build": cmd_build(only_complete=("--complete" in args))
    elif cmd == "buildfiles": cmd_build_files(only_complete=("--complete" in args))
    elif cmd == "pack":  cmd_pack()
    elif cmd == "stats": cmd_stats()
    elif cmd == "pending":
        n = cmd_pending(); sys.exit(0 if n > 0 else 1)
    elif cmd == "validate":
        tm = load_tm(); bad = 0
        for en, vi in tm.items():
            iss = tag_mismatch(en, vi)
            if iss:
                bad += 1
                print("  [tag] %s ... -> %s" % (en[:40], "; ".join(iss)))
        print("[validate] loi=%d / tong=%d" % (bad, len(tm)))
    else:
        print(__doc__)

if __name__ == "__main__":
    main()
