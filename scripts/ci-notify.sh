#!/bin/bash
# Проверка обязательных переменных
if [ -z "$TG_BOT_TOKEN" ] || [ -z "$TG_CHAT_ID" ]; then
  echo "ERROR: TG_BOT_TOKEN or TG_CHAT_ID not set!"
  exit 1
fi
TIME="10"
URL="https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage"
# Функция для преобразования ISO 8601 в UNIX timestamp
parse_date() {
  # Заменяем символ "T" на пробел и убираем "Z"
  date -d "$(echo "$1" | sed 's/T/ /; s/Z//')" +%s 2>/dev/null
}
# Получаем метки времени, используя функцию parse_date
START_TIMESTAMP=$(parse_date "$CI_JOB_STARTED_AT")
if [ -n "$CI_JOB_FINISHED_AT" ]; then
  END_TIMESTAMP=$(parse_date "$CI_JOB_FINISHED_AT")
else
  END_TIMESTAMP=""
fi
# Форматируем время старта
START_TIME=$( [ -n "$START_TIMESTAMP" ] && date -u -d "@$START_TIMESTAMP" +"%H:%M" 2>/dev/null || echo "N/A" )
# Вычисляем длительность (в секундах), если есть обе метки времени
if [ -n "$END_TIMESTAMP" ] && [ -n "$START_TIMESTAMP" ]; then
  DURATION=$(( END_TIMESTAMP - START_TIMESTAMP ))
else
  DURATION="N/A"
fi
# Формирование текста с расширенной информацией о пайплайне
TEXT="Deploy status: $1%0A%0A\
Project: <a href=\"$CI_PROJECT_URL\">$CI_PROJECT_NAME</a>%0A\
Pipeline: <a href=\"$CI_PIPELINE_URL\">#$CI_PIPELINE_IID</a>%0A\
Job: <a href=\"$CI_JOB_URL\">$CI_JOB_NAME</a>%0A\
Job ID: <a href=\"$CI_JOB_URL\">$CI_JOB_ID</a>%0A\
Commit: <a href=\"$CI_PROJECT_URL/-/commit/$CI_COMMIT_SHA\">${CI_COMMIT_SHA:0:8}</a>%0A\
Branch: <a href=\"$CI_PROJECT_URL/-/tree/$CI_COMMIT_REF_SLUG\">$CI_COMMIT_REF_SLUG</a>%0A\
Start Time: ${START_TIME}%0A\
Duration: ${DURATION} sec"
# Кодирование текста (замена символов, конфликтующих с URL)
ENCODED_TEXT=$(echo "$TEXT" | sed \
  -e 's/"/%22/g' \
  -e 's/</%3C/g' \
  -e 's/>/%3E/g' \
  -e 's/#/%23/g' \
  -e 's/&/%26/g')
# Отправка запроса
curl -s --max-time $TIME \
  -d "chat_id=$TG_CHAT_ID&parse_mode=HTML&disable_web_page_preview=1&text=$ENCODED_TEXT" \
  "$URL" > /dev/null
