# snmp-storage
скрипт расширения функционала net-snmp

Установка скрипта:
Скрипт состоит из двух частей, stor.sh и storage.sh. Необходимо скопировать оба файла в каталог на сервере, например /etc/snmp, убедиться в том, что оба файла имеют атрибут "исполняемый", если нет, то выполнить chmod +x stor.sh storage.sh. Добавить в crontab пользователя root запись запускающую скрипт stor.sh раз в день. Отредактировать конфигурационный файл net-snmp добавив в конец строку "pass /путь_к_файлу/storage.sh".
