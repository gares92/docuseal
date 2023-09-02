FROM ruby:3.2.2-alpine as webpack

ENV RAILS_ENV=production
ENV NODE_ENV=production

WORKDIR /app

RUN apk add --no-cache nodejs yarn git build-base && \
    gem install shakapacker

COPY ./package.json ./yarn.lock ./

RUN yarn install --network-timeout 1000000

COPY ./bin/shakapacker ./bin/shakapacker
COPY ./config/webpack ./config/webpack
COPY ./config/shakapacker.yml ./config/shakapacker.yml
COPY ./postcss.config.js ./postcss.config.js ./
COPY ./tailwind.config.js ./tailwind.config.js ./
COPY ./tailwind.form.config.js ./tailwind.form.config.js ./
COPY ./tailwind.application.config.js ./tailwind.application.config.js ./
COPY ./app/javascript ./app/javascript
COPY ./app/views ./app/views

RUN echo "gem 'shakapacker'" > Gemfile && ./bin/shakapacker

FROM ruby:3.2.2-alpine as app

ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"

WORKDIR /app

RUN apk add --no-cache build-base sqlite-dev libpq-dev mariadb-dev vips-dev vips-poppler vips-heif libc6-compat ttf-freefont

COPY ./Gemfile ./Gemfile.lock ./

RUN bundle update --bundler && bundle install && rm -rf ~/.bundle

COPY ./bin ./bin
COPY ./app ./app
COPY ./config ./config
COPY ./db ./db
COPY ./log ./log
COPY ./lib ./lib
COPY ./public ./public
COPY ./tmp ./tmp
COPY LICENSE README.md Rakefile config.ru ./

COPY --from=webpack /app/public/packs ./public/packs

RUN bundle exec bootsnap precompile --gemfile app/ lib/

WORKDIR /data/docuseal
ENV WORKDIR=/data/docuseal

EXPOSE 3000
CMD ["/app/bin/rails", "server"]
