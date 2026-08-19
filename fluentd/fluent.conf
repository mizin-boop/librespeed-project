<source>
  @type forward
  bind 0.0.0.0
  port 24224
</source>

<match **>
  @type elasticsearch
  host "#{ENV['ES_HOST']}"
  port "#{ENV['ES_PORT']}"
  scheme http
  logstash_format true
  logstash_prefix docker
  include_tag_key true
  tag_key docker_tag
  reconnect_on_error true
  reload_on_failure true
  request_timeout 30s

  <buffer tag,time>
    @type file
    path /fluentd/buffer/es
    timekey 1m
    timekey_wait 10s
    chunk_limit_size 10m
    total_limit_size 256m
    flush_mode interval
    flush_interval 5s
    retry_forever true
    retry_max_interval 30
  </buffer>
</match>
