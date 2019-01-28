FROM ruby:1.9.3
WORKDIR /usr/local/app
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install
