import requests
import json

url = 'https://kv-storage-tarantool.herokuapp.com'
kv_url = url+'/kv'

if __name__ == '__main__':
    broken_post_list = []
    broken_get_list = []
    put_list = []
    with open('./tests/posts.json') as json_file:
        post_list = json.load(json_file)
        for i in range(0, len(post_list)):
            if i % 2 == 0:
                broken_record = json.dumps({
                    "key": post_list[i]['key'],
                    "eulav": post_list[i]['value']
                })
            elif i % 2 == 1:
                broken_record = json.dumps({
                    "key": post_list[i]['key'],
                    "value": post_list[i]['value']
                })[:-1]

            broken_post_list += [broken_record]
            broken_get_list  += post_list[i]['key']+'!'

            new_value = post_list[i]['value'].copy()
            new_value['updated'] = True
            put_list += [dict({
                'key': post_list[i]['key'],
                'value':  new_value
            })]

    for record in broken_post_list:
        resp = requests.post(kv_url, data=record)
        assert resp.status_code == 400

    for record in post_list:
        resp = requests.get(kv_url + '/' + record['key'])
        assert resp.status_code == 404

        resp = requests.post(kv_url, json=record)
        assert resp.status_code == 200

        resp = requests.post(kv_url, json=record)
        assert resp.status_code == 409

    for record in put_list:
        resp = requests.get(kv_url + '/' + record['key'])
        assert resp.status_code == 200
        assert resp.json()['value'] != record['value']

        resp = requests.put(kv_url + '/' + record['key'], json={
            'value': record['value']
        })
        assert resp.status_code == 200

        resp = requests.get(kv_url + '/' + record['key'])
        assert resp.status_code == 200
        assert resp.json()['value'] == record['value']

    for record in post_list:
        resp = requests.delete(kv_url + '/' + record['key'])
        assert resp.status_code == 200

        resp = requests.get(kv_url + '/' + record['key'])
        assert resp.status_code == 404

        resp = requests.delete(kv_url + '/' + record['key'])
        assert resp.status_code == 404
