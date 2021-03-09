#!/bin/bash
sudo echo '' > apache.log
sudo echo '' > elasticsearch.log
sudo echo '' > kibana.log
sudo echo '' > logstash.log
sudo echo '' > redis.log
sudo rm -f redis/data/*
sudo rm -rf elasticsearch/data/*
