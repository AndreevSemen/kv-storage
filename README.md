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


## Некоректное тело запроса
При попытке доступа к записи по несуществующему ключу
возвращется статус 404 и json:
```json
{
    "error": "key not found"
}
```

## Создать запись
### Body
```json
{
    "key": "awesome key",
    "value": {
        ...SOME ARBITRARY JSON...
    }
}
```
### Response
В случае успеха возвращается статус `200` и json в теле:
```json
{
    "result": "record created"
}
```

При попытке создать запись по существующему ключу
возвращется статус 409 и json:
```json
{
    "error": "key already exists"
}
```


## Получить запись
### Response
В случае успеха возвращается статус `200` и json в теле:
```json
{
    "value": {
        ...SOME ARBITRARY JSON...
    }
}
```


## Обновить запись
### Body
```json
{
    "value": {
        ...SOME ARBITRARY JSON...
    }
}
```
### Response
В случае успеха возвращается статус `200` и json в теле:
```json
{
    "result": "record updated"
}
```

## Удалить запись
### Response
В случае успеха возвращается статус `200` и json в теле:
```json
{
    "deleted": {
        "key": "awesome key",
        "value": {
            ...SOME ARBITRARY JSON...
        }
    }
}
```

