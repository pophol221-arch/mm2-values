MM2 Trade Values — автообновление цен Supreme Values
=====================================================

Как это работает:
  канал Supreme Values -> (Follow) -> канал на твоём сервере -> бот bot.py
  -> values.json на GitHub -> скрипт trade_values.lua в Delta/Xeno

1. GitHub
   - Создай публичный репозиторий mm2-values.
   - Загрузи в него values.json из этой папки (Add file -> Upload files).
     В нём только цены из последнего обновления; остальные допиши с сайта.
   - Создай токен: Settings -> Developer settings -> Fine-grained tokens ->
     Generate new token. Repository access: только mm2-values.
     Permissions -> Contents: Read and write. Скопируй токен.

2. Discord-бот
   - https://discord.com/developers/applications -> New Application.
   - Вкладка Bot -> Reset Token -> скопируй токен.
   - Там же включи "MESSAGE CONTENT INTENT".
   - OAuth2 -> URL Generator: scopes "bot", права "View Channels" и
     "Read Message History". Открой ссылку и добавь бота на СВОЙ сервер.
   - В Discord: Настройки -> Расширенные -> Режим разработчика (вкл).
     ПКМ по каналу, куда приходят обновления Supreme Values -> Копировать ID.

3. Настройка и запуск (на ПК)
   - Скопируй config.example.json в config.json и впиши токены, ID канала
     и имя репозитория (например "pophol221-arch/mm2-values").
   - В этой папке:
       pip install discord.py
       python bot.py
   - Бот пишет в консоль каждое найденное изменение цены.
     Пока бот выключен — ничего не теряется: при запуске он дочитает
     пропущенные сообщения.

4. Roblox
   - В trade_values.lua замени ТВОЙ_НИК в VALUES_URL на свой ник GitHub.
   - Вставь скрипт в Delta (вкладка >_) -> Execute / Save.
   - Цены перекачиваются при каждом открытии трейда.

НЕ публикуй config.json и не вставляй токены в Roblox-скрипт.
