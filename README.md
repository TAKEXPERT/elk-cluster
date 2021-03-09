# Configure ELK + Redis for processing Apache Access Log in Docker Environment

## Recommented Host Environment:
- Ubuntu 20.04
- Python 3 (for running python scripts)
- Redis (for easy connect to redis-cli from host)
## Docker Images in single node:
- Apache ( httpd:2.4 )
- Redis (redis:latest)
- Logstash ( logstash:7.10.1 )
- Elastic Search ( elasticsearch:7.10.1 )
- Kibana ( kibana:7.10.1 )

## How to Ready Environment in single node:
0. Ready Host Environment (Ubuntu + Python3 + Redis)
1. [Optional] Activate fastest mirrors for Ubuntu
2. [Prefered] Update Ubuntu
3. Install Docker on Host
4. Install Docker Images
5. Setup custom config files and Persist project data
6. Setup virtualenv for python scripts
7. Run Project
8. Monitoring and view logs
9. Working with Kibana

## 1. [Optional] Activate fastest mirrors for Ubuntu
this config can speed up download ubuntu packages.

for enable fastest mirrors open `/etc/apt/sorces.list` and append this lines on head of file:
```sh
deb mirror://mirrors.ubuntu.com/mirrors.txt focal main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt focal-updates main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt focal-backports main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt focal-security main restricted universe multiverse
```

## 2. [Prefered] Update Ubuntu
Update Ubuntu Packages before ready environment
```sh
sudo apt-get update
sudo apt-get dist-upgrade -y
```
then reboot system.

## 3. Install Docker on Host
first uninstall docker if installed
```sh
sudo apt-get remove -y docker* containerd runc
```
install fresh docker packages:
```sh
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
```

## 4. Install Docker Images
```sh
sudo docker pull httpd:2.4
sudo docker pull redis:latest
sudo docker pull logstash:7.10.1
sudo docker pull elasticsearch:7.10.1
sudo docker pull kibana:7.10.1
```

## 5. Setup custom config files and Persist project data
> assume working directory is current directory (PWD)
if you want to change working directory must change `working_dir` path in `run.sh`
> assume `redis` host port mapped to `6380`
> assume `elasticsearch` host port mapped to `9200`, `9300`
> assume `kibana` host port mapped to `5601`
> assume docker containers run in bridge mode

### 5.1. redis
```sh
mkdir -p redis/data
```

### 5.2. logstash
```sh
mkdir -p logstash/pipeline
mkdir -p logstash/config
touch logstash/config/logstash.yml
touch logstash/pipeline/logstash.conf
```
insert this lines in `logstash/config/logstash.yml`
```sh
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: [ "http://172.17.0.5:9200" ]
```
insert this lines in `logstash/pipeline/logstash.conf`
```sh
input {
  redis {
    host => "172.17.0.3"
    port => 6379
    data_type => "list"
    key => "test"
  }
}
  filter {
    grok {
      match => { "message" => "%{COMBINEDAPACHELOG}" }
    }
    mutate {
		convert => {"timestamp" => "string"}
	}
	date {
		match => ["timestamp", "ISO8601"]
	}
}
output {
  elasticsearch { hosts => ["172.17.0.5:9200"] }
  stdout {
    codec => rubydebug
  }
}
```
### 5.3. elasticsearch
```sh
mkdir -p elasticsearch/config
mkdir -p elasticsearch/data
touch elasticsearch/config/elasticsearch.yml
```
insert this lines in `elasticsearch/config/elasticsearch.yml`
```sh
cluster.name: "demo-elk"
node.name: "elk-1"
network.host: 0.0.0.0
discovery.type: single-node
```
### 5.4. kibana
```sh
mkdir -p kibana/config
touch kibana/config/kibana.yml
```
insert this lines in `kibana/config/kibana.yml`
```sh
server.name: kibana
server.host: "0"
elasticsearch.hosts: [ "http://172.17.0.5:9200" ]
monitoring.ui.container.elasticsearch.enabled: true
```

# 6. Setup virtualenv for python scripts
install python virtualenv package on Ubuntu
```sh
sudo apt install -y python3-pip
sudo apt install -y build-essential libssl-dev libffi-dev python3-dev
sudo apt install -y python3-venv
python3 -m venv ./venv
```
install python scripts dependency packages in virtual environment
```sh
source ./venv/bin/activate
pip3 install -r requirements.txt
```

# 7. Run Project
for Run project we need to execute `run.sh` , `main.py`, `fake_request.py`
first execute `run.sh`
```sh
bash ./run.sh
```
then python scripts must execute in virtualenv
```sh
source ./venv/bin/activate
python3 ./main.py
python3 ./fake_request
```
> note all of scripts working with `STDIN` and `STDOUT`.
so execute them in terminal separately.
recommended using `tmux`

for using `tmux` you must install it
```sh
sudo apt install -y tmux
```

# 8. Monitoring and view logs
### monitor main logs
logstash, elasticsearch and kibana logs stored in `working directory` that defined `working_dir` in `run.sh`
execute this commands to view logs

> note: assume redis host port mapped to 6380

```sh
redis-cli -p 6380 monitor
tail -f ./logstash.log
tail -f ./elasticsearch.log
tail -f ./kibana.log
```
### useful command for monitoring docker containers
to view running docker containers at realtime, you can use this command
```sh
watch "sudo docker ps --format '{{.Names}}'"
```

### clean logs
if you want to clean project logs and data you can execute `clean.sh`
```sh
bash ./clean.sh
```

# 9. Working with Kibana
after run project, we must configure kibana.
open `http://localhost:5601` in browser
and create `index pattern` with name of `logstash*`.
then set `time field` to `@timestamp`
now you can view collected logs in kibana `discover` section
