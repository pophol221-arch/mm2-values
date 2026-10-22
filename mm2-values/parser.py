"""Разбор сообщений «SUPREME VALUES UPDATE» из Discord.

Понимает строки вида:
  Corrupt reduced to 340
  Sunrise reduced to 875 [850-875]
  Alien Set increased to 3,925 [3,925-4,025], stability changed ...
  Blizzard reduced to 280, demand reduced to 3
и пропускает строки про demand / rarity / stability без цены.
"""
import re

VERBS = r"(?:reduced|increased|raised|lowered|decreased|dropped|rose|changed|adjusted|corrected|set)"
LINE_RE = re.compile(
    rf"^\s*[-•*]?\s*(?P<name>.+?)\s+{VERBS}\s+(?:from\s+[\d,.]+\s+)?to\s+(?P<value>\d[\d,]*(?:\.\d+)?)\s*(?P<k>[kK])?\b",
)
# «Gingerscope's demand reduced to 5», «<3's rarity reduced to 2» — это не цена
NOT_VALUE_RE = re.compile(r"(?:'s|’s)?\s+(?:demand|rarity|stability)$", re.I)


def clean(text: str) -> str:
    # убираем markdown Discord: **жирный**, __подчёркнутый__, *курсив*
    return re.sub(r"[*_~`]+", "", text)


def parse_update(text: str) -> dict[str, float]:
    """Возвращает {название: цена} для всех строк с новой ценой."""
    found: dict[str, float] = {}
    for raw in clean(text).splitlines():
        m = LINE_RE.match(raw)
        if not m:
            continue
        name = m.group("name").strip()
        if NOT_VALUE_RE.search(name):
            continue
        value = float(m.group("value").replace(",", ""))
        if m.group("k"):
            value *= 1000
        found[name] = int(value) if value.is_integer() else value
    return found


# «Name's demand reduced to 5» — строка без цены, но с изменением спроса/редкости/стабильности
OWNER_RE = re.compile(r"^\s*[-•*]?\s*(?P<name>.+?)(?:'s|’s)\s+(?:demand|rarity|stability)(?![a-z])", re.I)
RANGE_RE = re.compile(r"\[\s*([\d,.]+)\s*-\s*([\d,.]+)\s*\]")
DEMAND_RE = re.compile(r"demand\s+\w+\s+(?:from\s+\d+\s+)?to\s+(\d+)", re.I)
RARITY_RE = re.compile(r"rarity\s+\w+\s+(?:from\s+\d+\s+)?to\s+(\d+)", re.I)
STAB_RE = re.compile(r"stability\s+changed\s+(?:from\s+[\"“”]?[^\"“”]*[\"“”]?\s+)?to\s+[\"“”]?([^\"“”,]+)", re.I)


def parse_info(text: str) -> dict[str, dict]:
    """{название: {r: "1,300 - 1,325", d: 5, y: 3, s: "Doing Well"}} — только то, что есть в строке."""
    found: dict[str, dict] = {}
    for raw in clean(text).splitlines():
        m = LINE_RE.match(raw)
        name = None
        if m and not NOT_VALUE_RE.search(m.group("name").strip()):
            name = m.group("name").strip()
        else:
            m2 = OWNER_RE.match(raw)
            if m2:
                name = m2.group("name").strip()
        if not name:
            continue
        info = {}
        r = RANGE_RE.search(raw)
        if r:
            info["r"] = f"{r.group(1)} - {r.group(2)}"
        d = DEMAND_RE.search(raw)
        if d:
            info["d"] = int(d.group(1))
        y = RARITY_RE.search(raw)
        if y:
            info["y"] = int(y.group(1))
        st = STAB_RE.search(raw)
        if st:
            info["s"] = st.group(1).strip()
        found[name] = info
    return found


if __name__ == "__main__":
    sample = """**SUPREME VALUES UPDATE 13/10/2026 22:26 UTC (13/10/2026):**

__**UNIQUES:**__
Corrupt reduced to 340

__**ANCIENTS:**__
Gingerscope's demand reduced to 5
Traveler's Axe reduced to 7,100 [7,000-7,100]
Celestial reduced to 2,100 [2,000-2,100]
Vampire's Axe reduced to 1,500 [1,475-1,500], stability changed from "Stable" to "Underpaid For"

__**CHROMAS:**__
Chroma Evergun reduced to 53,000
Chroma Raygun reduced to 14,500, demand reduced to 5
Sunrise reduced to 875 [850-875]
Blizzard reduced to 280, demand reduced to 3

__**PETS:**__
<3's rarity reduced to 2
Mechbug's rarity reduced to 2

__**SETS:**__
Chroma Ever Set reduced to 92,000
Alien Set increased to 3,925 [3,925-4,025]
"""
    sample += """Emberscythe __**corrected**__ to 1,800 [1,800-1,900]
Traveler's Set increased to 12,700 [12,700-12,800], stability changed from "Stable" to "Doing Well"
"""
    for k, v in parse_update(sample).items():
        print(f"{k!r:24} {v}")
    for k, v in parse_info(sample).items():
        print("info", f"{k!r:24} {v}")
