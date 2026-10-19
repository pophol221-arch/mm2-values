"""Бот: читает обновления цен Supreme Values в твоём Discord-канале
и сохраняет их в values.json в твоём GitHub-репозитории.

Запуск:  python bot.py   (настройки в config.json)
"""
import asyncio
import base64
import json
from datetime import datetime, timezone
from pathlib import Path

import aiohttp
import discord

from parser import parse_update

CFG = json.loads((Path(__file__).parent / "config.json").read_text(encoding="utf-8"))
CHANNEL_ID = int(CFG["channel_id"])
GH_API = f"https://api.github.com/repos/{CFG['github_repo']}/contents/{CFG.get('github_path', 'values.json')}"
GH_HEADERS = {
    "Authorization": f"Bearer {CFG['github_token']}",
    "Accept": "application/vnd.github+json",
}
BRANCH = CFG.get("github_branch", "main")

intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)

state = {"updated": None, "last_message_id": 0, "values": {}}
sha = None  # версия файла на GitHub, нужна для перезаписи
lock = asyncio.Lock()


def message_text(msg: discord.Message) -> str:
    parts = [msg.content or ""]
    for e in msg.embeds:
        parts += [e.title or "", e.description or ""]
        parts += [f"{f.name}\n{f.value}" for f in e.fields]
    return "\n".join(parts)


async def gh_load(session: aiohttp.ClientSession):
    global state, sha
    async with session.get(GH_API, headers=GH_HEADERS, params={"ref": BRANCH}) as r:
        if r.status == 404:
            print("[gh] values.json ещё нет — создам при первом обновлении")
            return
        r.raise_for_status()
        data = await r.json()
    sha = data["sha"]
    loaded = json.loads(base64.b64decode(data["content"]).decode("utf-8"))
    # можно положить в репозиторий просто {"Corrupt": 340, ...} — тоже поймём
    if "values" not in loaded:
        loaded = {"updated": None, "last_message_id": 0, "values": loaded}
    state = loaded
    print(f"[gh] загружено цен: {len(state['values'])}")


async def gh_save(session: aiohttp.ClientSession, note: str):
    global sha
    body = {
        "message": f"Цены: {note}",
        "content": base64.b64encode(
            json.dumps(state, ensure_ascii=False, indent=1, sort_keys=True).encode("utf-8")
        ).decode(),
        "branch": BRANCH,
    }
    if sha:
        body["sha"] = sha
    async with session.put(GH_API, headers=GH_HEADERS, json=body) as r:
        if r.status >= 300:
            print("[gh] ошибка сохранения:", r.status, await r.text())
            return
        sha = (await r.json())["content"]["sha"]
    print(f"[gh] сохранено ({note})")


async def apply(msg: discord.Message, session: aiohttp.ClientSession, save: bool = True) -> int:
    changes = parse_update(message_text(msg))
    if msg.id > int(state.get("last_message_id") or 0):
        state["last_message_id"] = msg.id
    if not changes:
        return 0
    for name, value in changes.items():
        old = state["values"].get(name)
        state["values"][name] = value
        print(f"  {name}: {old} -> {value}")
    state["updated"] = msg.created_at.astimezone(timezone.utc).isoformat()
    if save:
        await gh_save(session, f"{len(changes)} изм. из сообщения {msg.id}")
    return len(changes)


@client.event
async def on_ready():
    print(f"[discord] вошёл как {client.user}")
    channel = client.get_channel(CHANNEL_ID) or await client.fetch_channel(CHANNEL_ID)
    async with lock, aiohttp.ClientSession() as session:
        await gh_load(session)
        # догоняем сообщения, пришедшие, пока бот был выключен
        after = discord.Object(id=int(state.get("last_message_id") or 0)) if state.get("last_message_id") else None
        total = 0
        async for msg in channel.history(limit=None, after=after, oldest_first=True):
            total += await apply(msg, session, save=False)
        if total:
            await gh_save(session, f"догнал {total} изм.")
    print(f"[discord] слушаю канал #{channel}")


@client.event
async def on_message(msg: discord.Message):
    if msg.channel.id != CHANNEL_ID:
        return
    async with lock, aiohttp.ClientSession() as session:
        print(f"[discord] новое сообщение {msg.id} ({datetime.now():%H:%M})")
        if not await apply(msg, session):
            print("  цен не найдено")


client.run(CFG["discord_token"])
