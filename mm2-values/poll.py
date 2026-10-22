"""Обновление цен без включённого компа: запускается GitHub Actions раз в ~15 минут.
Читает новые сообщения Discord-канала (после last_message_id) и дописывает их в values.json —
то же самое, что делает bot.py, только одним заходом, без постоянного подключения.

Нужны секреты репозитория: DISCORD_TOKEN, CHANNEL_ID.
Локально: DISCORD_TOKEN=... CHANNEL_ID=... python poll.py [--dry]
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

from parser import parse_info, parse_update

HERE = Path(__file__).parent
VALUES = HERE / "values.json"
API = "https://discord.com/api/v10"


def discord_get(path: str):
    req = urllib.request.Request(API + path, headers={
        "Authorization": "Bot " + os.environ["DISCORD_TOKEN"].strip(),
        "User-Agent": "mm2-values-poll (github actions, 1.0)",
    })
    for _ in range(5):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 429:  # лимит запросов — ждём сколько скажут
                time.sleep(float(json.load(e).get("retry_after", 2)) + 0.5)
                continue
            raise
    raise RuntimeError("Discord: слишком много запросов")


def message_text(m: dict) -> str:
    parts = [m.get("content") or ""]
    for e in m.get("embeds") or []:
        parts += [e.get("title") or "", e.get("description") or ""]
        parts += [f"{f.get('name', '')}\n{f.get('value', '')}" for f in e.get("fields") or []]
    return "\n".join(parts)


def main() -> int:
    dry = "--dry" in sys.argv
    channel = os.environ["CHANNEL_ID"].strip()
    state = json.loads(VALUES.read_text(encoding="utf-8"))
    after = int(state.get("last_message_id") or 0)
    # REPLAY=N — разово перечитать последние N сообщений (догнать то, что раньше не разбиралось)
    replay = int(os.environ.get("REPLAY") or 0)
    if replay:
        recent = discord_get(f"/channels/{channel}/messages?limit={min(replay, 100)}")
        if recent:
            after = min(int(m["id"]) for m in recent) - 1

    # все сообщения после last_message_id, по 100 за запрос, от старых к новым
    msgs = []
    while True:
        batch = discord_get(f"/channels/{channel}/messages?limit=100&after={after}")
        if not batch:
            break
        batch.sort(key=lambda m: int(m["id"]))
        msgs += batch
        after = int(batch[-1]["id"])
        if len(batch) < 100:
            break

    total = 0
    for m in msgs:
        mid = int(m["id"])
        if mid > int(state.get("last_message_id") or 0):
            state["last_message_id"] = mid
        text = message_text(m)
        changes = parse_update(text)
        # диапазон, спрос, редкость, стабильность — как на сайте
        infos = state.setdefault("info", {})
        for name, upd in parse_info(text).items():
            cur = infos.setdefault(name, {})
            cur.update(upd)
            if name in changes and "r" not in upd and cur.get("r"):
                # цена поменялась, а нового диапазона нет: старый, если цена в него не попадает, — устарел
                try:
                    lo, hi = (float(x.replace(",", "")) for x in cur["r"].split(" - "))
                    if not lo <= changes[name] <= hi:
                        del cur["r"]
                except ValueError:
                    pass
        if not changes:
            continue
        ts = datetime.fromisoformat(m["timestamp"])
        unix = int(ts.timestamp())
        for name, value in changes.items():
            old = state["values"].get(name)
            state["values"][name] = value
            if old is not None and old != value:
                # для стрелок ▲▼ в скрипте
                state.setdefault("changes", {})[name] = value - old
            # для графиков: точка (время сообщения, цена); храним последние 200
            hist = state.setdefault("history", {}).setdefault(name, [])
            if not hist and old is not None:
                hist.append([unix - 1, old])
            # повтор той же цены или более старое сообщение (перечитывание) в историю не пишем
            if not (hist and (hist[-1][1] == value or hist[-1][0] >= unix)):
                hist.append([unix, value])
            hist.sort(key=lambda p: p[0])
            del hist[:-200]
            print(f"  {name}: {old} -> {value}")
        state["updated"] = ts.astimezone(timezone.utc).isoformat()
        total += len(changes)

    print(f"новых сообщений: {len(msgs)}, изменений цен: {total}")
    if msgs and not dry:
        VALUES.write_text(json.dumps(state, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    # для подписи коммита
    out = os.environ.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a", encoding="utf-8") as f:
            f.write(f"changes={total}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
