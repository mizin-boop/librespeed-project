FROM php:8.5-fpm-bookworm

ARG LIBRESPEED_VERSION=v6.2.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" pdo pdo_mysql gd \
    && curl -fsSL "https://github.com/librespeed/speedtest/archive/refs/tags/${LIBRESPEED_VERSION}.tar.gz" -o /tmp/librespeed.tar.gz \
    && mkdir -p /opt/librespeed \
    && tar -xzf /tmp/librespeed.tar.gz --strip-components=1 -C /opt/librespeed \
    && rm -rf /var/lib/apt/lists/* /tmp/librespeed.tar.gz

COPY app/entrypoint.sh /usr/local/bin/librespeed-entrypoint.sh
RUN chmod +x /usr/local/bin/librespeed-entrypoint.sh \
    && { \
         echo '[www]'; \
         echo 'catch_workers_output = yes'; \
         echo 'decorate_workers_output = no'; \
         echo 'access.log = /proc/self/fd/2'; \
         echo 'clear_env = no'; \
       } > /usr/local/etc/php-fpm.d/zz-librespeed.conf

WORKDIR /var/www/html
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/librespeed-entrypoint.sh"]
CMD ["php-fpm", "-F"]
