import subprocess
import shlex
import re
import json
import redis
from apachelogs import LogParser

# ------------------apache settings------------------#
apache_container_name = "apache"
parser = LogParser("%h %l %u %t \"%r\" %>s %b")
# ------------------redis settings------------------#
redis_host = '172.17.0.3'
redis_port = 6379
redis_db = 0
redis_set_name = 'test'
# command for listen to apache access log
command = "sudo docker logs --follow " + apache_container_name

# ------------------functions------------------#
def connect_to_redis():
    redis_client = redis.StrictRedis(host=redis_host,
                                     port=redis_port,
                                     db=redis_db)
    if not redis_client.ping():
        print('can not stablished connection to redis server')
        exit(1)
    return redis_client
def apache_log_parse(redis_client, inp):
        parser = LogParser("%h %l %u %t \"%r\" %>s %b")
        entry = parser.parse(inp)
        j = json.dumps({
            "ip": entry.remote_host,
            "ui": entry.remote_logname,
            "usr": entry.remote_user,
            "@timestamp": str(entry.request_time_fields["timestamp"].isoformat()),
            "request_line": entry.request_line,
            "status": entry.final_status,
            "size": entry.bytes_sent
        })
        redis_client.lpush(redis_set_name, j)
        print("stored in list:")
        print(redis_client.llen(redis_set_name))
# ------------------main------------------#
# try to connect to redis server
redis_client = connect_to_redis()
# logging apache access file
process = subprocess.Popen(shlex.split(command), stdout=subprocess.PIPE)
while True:
    output = process.stdout.readline()
    if output:
        apache_log_parse(redis_client, output.decode('utf-8').strip())
