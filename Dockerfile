FROM bitnami/ruby:2.7.1

RUN apt-get update -qq \
    && mkdir /gems \
    && apt install -y locales build-essential sudo vim iputils-ping tzdata libjemalloc-dev gcc make \
    && rm -rf /var/lib/apt/lists/* \
    && gem install bundler:2.0.2 --no-document \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure -f noninteractive locales \
    && /usr/sbin/update-locale LANG=en_US.UTF-8 \
    && cd /tmp \
    && wget http://download.redis.io/redis-stable.tar.gz \
    && tar xvzf redis-stable.tar.gz \
    && cd redis-stable \
    && make \
    && cp src/redis-cli /usr/local/bin/ \
    && chmod 755 /usr/local/bin/redis-cli

ENV LC_ALL en_US.UTF-8

ENV PATH=/app/bin:$PATH
ENV BUNDLE_PATH "/gems"

ADD Gemfile /app/
ADD Gemfile.lock /app/
WORKDIR /app
RUN bundle config set without 'development test' && bundle install --jobs 20 --retry 10

COPY . /app/

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
