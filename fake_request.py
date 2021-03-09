import requests
from random import seed
from random import randint
from time import sleep

#--------------------Main--------------------#
seed()
index = 0
while True:
    sleep(0.3)
    index = index + 1
    path = ''
    if randint(0,1) == 1:
        path = str(randint(1000,2000))
    try:
        r = requests.get('http://localhost/' + path)
    except requests.exceptions.ConnectionError:
        continue
    print('t: ', index, 'code: ', r.status_code)
