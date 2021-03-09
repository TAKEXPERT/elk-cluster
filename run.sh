#!/bin/bash

#------------------- general settings -------------------#
working_dir="$(pwd)"
python_exec="/usr/bin/python3.8"
shared_docker_network="bridge"
#------------------- apache settings -------------------#
apache_image_name="httpd:2.4"
apache_container_name="apache"
apache_host_port="80"
#------------------- redis settings -------------------#
redis_image_name="redis"
redis_container_name="redis"
redis_host_port="6380"
#------------------- logstash settings -------------------#
logstash_image_name="logstash:7.10.1"
logstash_container_name="logstash"
#------------------- elasticsearch settings -------------------#
elasticsearch_image_name="elasticsearch:7.10.1"
elasticsearch_container_name="elasticsearch"
elasticsearch_host_port="9200"
elasticsearch_communicate_host_port="9300"
#------------------- elasticsearch settings -------------------#
kibana_image_name="kibana:7.10.1"
kibana_container_name="kibana"
kibana_host_port="5601"

#------------------- Functions -------------------#
# kill specific running old container
kill_old_container(){
	cname=$1
	if [ ! -z "$(sudo docker ps -q -f name=$cname)" ]; then
		#stop old container
		echo -e "stopping $cname container ..."
		sudo docker stop $cname &> /dev/null
	fi
}

# start apache container
start_apache(){
	kill_old_container $apache_container_name
	echo "starting apache container ..."
	sudo docker run --rm --name $apache_container_name \
	 --network $shared_docker_network \
	 -p $apache_host_port:80 \
	 -d $apache_image_name &> /dev/null
}

# start redis container
start_redis(){
	kill_old_container $redis_container_name
	echo "starting redis container ..."
	if [ ! -d "$working_dir/redis/data" ]; then
		mkdir -p "$working_dir/redis/data"
	fi
	sudo docker run --rm --name $redis_container_name \
	 --network $shared_docker_network \
	 -p $redis_host_port:6379 \
	 -v "$working_dir/redis/data"/:/data \
	 -d $redis_image_name redis-server --appendonly yes &> ./redis.log
}

# start logstash container
start_logstash(){
	kill_old_container $logstash_container_name
	echo "starting logstash container ..."
	if [ ! -d "$working_dir/logstash/pipeline" ]; then
		mkdir -p "$working_dir/logstash/pipeline"
	fi
	if [ ! -d "$working_dir/logstash/config" ]; then
		mkdir -p "$working_dir/logstash/config"
	fi
	sudo docker run --rm --name $logstash_container_name \
	 --network $shared_docker_network \
	 -v "$working_dir/logstash/pipeline/logstash.conf":/usr/share/logstash/pipeline/logstash.conf \
	 -v "$working_dir/logstash/config/logstash.yml":/usr/share/logstash/config/logstash.yml \
	 $logstash_image_name &> ./logstash.log &
}

# start elasticsearch container
start_elasticsearch(){
	kill_old_container $elasticsearch_container_name
	echo "starting elasticsearch container ..."
	if [ ! -d "$working_dir/elasticsearch/config" ]; then
		mkdir -p "$working_dir/elasticsearch/config"
	fi
	if [ ! -d "$working_dir/elasticsearch/data" ]; then
		mkdir -p "$working_dir/elasticsearch/data"
	fi
	sudo docker run --rm --name $elasticsearch_container_name \
	 --network $shared_docker_network \
	 -p $elasticsearch_host_port:9200 \
	 -p $elasticsearch_communicate_host_port:9300 \
	 -v "$working_dir/elasticsearch/config/elasticsearch.yml":/usr/share/elasticsearch/config/elasticsearch.yml \
	 -v "$working_dir/elasticsearch/data":/usr/share/elasticsearch/data \
	 $elasticsearch_image_name &> ./elasticsearch.log &

}

# start kibana container
start_kibana(){
	kill_old_container $kibana_container_name
	echo "starting kibana container ..."
	if [ ! -d "$working_dir/kibana/config" ]; then
		mkdir -p "$working_dir/kibana/config"
	fi
	sudo docker run --rm --name $kibana_container_name \
	 --network $shared_docker_network \
	 -p $kibana_host_port:5601 \
	 -v "$working_dir/kibana/config/kibana.yml":/usr/share/kibana/config/kibana.yml \
	 $kibana_image_name &> ./kibana.log &
}

# wait for terminate script by user
wait_for_terminate(){
	echo "script is running, to terminate Press 'q'"
	count=0
	while : ; do
	read -n 1 k <&1
	if [[ $k = q ]] ; then
		kill_old_container $kibana_container_name
		kill_old_container $elasticsearch_container_name
		kill_old_container $logstash_container_name
		kill_old_container $redis_container_name
		kill_old_container $apache_container_name
		printf "\nQuitting from the program\n"
	break
	else
	((count=$count+1))
	fi
	done
}

#------------------- Main -------------------#
start_apache
start_redis
start_logstash
start_elasticsearch
start_kibana
wait_for_terminate
