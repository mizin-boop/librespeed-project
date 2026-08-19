FROM fluent/fluentd:v1.17-debian-1.0
USER root
RUN gem install fluent-plugin-elasticsearch -v 5.4.3 --no-document \
    && gem sources --clear-all \
    && rm -rf /tmp/* /var/tmp/*
USER fluent
