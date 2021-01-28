docker run -d --name kibana --network=host -e ELASTICSEARCH_HOSTS=http://127.0.0.1:9200 -e I18N_LOCALE=zh-CN kibana:7.9.3
