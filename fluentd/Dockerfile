FROM fluent/fluentd:v1.19-debian-2

USER root

RUN gem install elasticsearch -v 7.10.1 --no-document \
    && gem install fluent-plugin-elasticsearch -v 5.2.5 --no-document \
    && mkdir -p /fluentd/buffer/es \
    && chown -R fluent:fluent /fluentd/buffer

USER fluent
