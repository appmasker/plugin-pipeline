FROM caddy:2.6.0-builder AS builder

ARG ACCESS_TOKEN_USR="nothing"
ARG ACCESS_TOKEN_PWD="nothing"
ARG APPMASKER_ACCESS_TOKEN="nothing"
ARG PLUGIN_REPOS=""

ENV GOPRIVATE="github.com/${ACCESS_TOKEN_USR}/*,github.com/appmasker/*"

RUN printf "machine github.com\n\
    login ${ACCESS_TOKEN_USR}\n\
    password ${ACCESS_TOKEN_PWD}\n\
    \n\
    machine api.github.com\n\
    login ${ACCESS_TOKEN_USR}\n\
    password ${ACCESS_TOKEN_PWD}\n"\
    >> /root/.netrc
RUN chmod 600 /root/.netrc

COPY ./plugin-pipeline /plugin-pipeline/

RUN chmod +x /plugin-pipeline/build-caddy.sh && /plugin-pipeline/build-caddy.sh $APPMASKER_ACCESS_TOKEN $ACCESS_TOKEN_USR $ACCESS_TOKEN_PWD $PLUGIN_REPOS

FROM caddy:2.6.0

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY ./plugin-pipeline/managed-config.json /etc/caddy/

CMD ["caddy", "run", "--config", "/etc/caddy/managed-config.json"]  