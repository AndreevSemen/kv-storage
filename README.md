# Tarantool kv-хранилище

Приложение, реализующие kv-хранилище развернуто с помощью
сервиса [Heroku](https://www.heroku.com) по следующему адресу:
https://kv-storage-tarantool.herokuapp.com

## Стек
- ***Tarantool*** - kv-хранилище
- ***Lua*** - сервис-менеджер kv-хранилища
- ***Docker*** - контейниризация сервиса
- ***Heroku*** - дейплой сервиса в публичном облаке

## API
Хранилище имеет следующее API:
| Handle                                                      | Method    | Method    |
|-------------------------------------------------------------|-----------|-----------|
| Создать новую запись с ключем `key` и значением `JSONValue` | `POST`    | `/kv`     |
| Получить значение записи по ключу `key`                     | `GET`     | `/kv/key` |
| Обновить значение записи по ключу `key`                     | `PUT`     | `/kv/key` |
| Удалить запись с ключем `key`                               | `DELETE`  | `/kv/key` |


## Run tests

Чтобы запустить тесты, достаточно выполнить команду:
```shell script
python tests/test.py
```

## Navigation

`kvstorage.lua` - ***Lua***-скрипт, реализующий сервис над ***Tarantool***

`tests` - директория с тестами

`Dockerfile` - образ для запуска контейнера на ***Heroku***


## Некоректное тело запроса
При попытке доступа к записи по несуществующему ключу
возвращется статус 404 и json:
```JSON
{
    "error": "key not found"
}
```

## Создать запись
### Body
```JSON
{
    "key": "awesome key",
    "value": {
        "SOME ARBITRARY JSON": {}
    }
}
```
### Response
В случае успеха возвращается статус `200` и json в теле:
```JSON
{
    "result": "record created"
}
```

При попытке создать запись по существующему ключу
возвращется статус 409 и json:
```JSON
{
    "error": "key already exists"
}
```


## Получить запись
### Response
В случае успеха возвращается статус `200` и json в теле:
```JSON
{
    "value": {
        "SOME ARBITRARY JSON": {}
    }
}
```


## Обновить запись
### Body
```JSON
{
    "value": {
        "SOME ARBITRARY JSON": {}
    }
}
```
### Response
В случае успеха возвращается статус `200` и json в теле:
```JSON
{
    "result": "record updated"
}
```

## Удалить запись
### Response
В случае успеха возвращается статус `200` и json в теле:
```JSON
{
    "deleted": {
        "key": "awesome key",
        "value": {
            "SOME ARBITRARY JSON": {}
        }
    }
}
```

