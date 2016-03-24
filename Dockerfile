FROM ruby:2.2.2

RUN mkdir -p /u/app
WORKDIR /u/app

EXPOSE 3000
CMD [ "bundle", "exec", "rake" ]

ADD . /u/app
RUN bundle install --jobs 8
