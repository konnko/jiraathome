ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=28.3.1
ARG DEBIAN_VERSION=trixie-20260223-slim
FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS builder

RUN apt-get update && apt-get install -y --no-install-recommends build-essential ca-certificates nodejs npm \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV MIX_ENV=prod ERL_FLAGS="+JMsingle true"
RUN mix local.hex --force && mix local.rebar --force
COPY mix.exs mix.lock ./
COPY config/config.exs config/prod.exs config/
RUN mix deps.get --only prod && mix deps.compile
COPY lib lib
COPY priv priv
COPY assets assets
RUN mix assets.setup && mix compile && mix assets.deploy
COPY config/runtime.exs config/
RUN mix release

FROM debian:trixie-20260223-slim AS runner
RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 openssl libncurses6 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=C.UTF-8 MIX_ENV=prod DATABASE_PATH=/data/jiraathome.db
WORKDIR /app
RUN mkdir /data && chown nobody:nogroup /data
COPY --from=builder --chown=nobody:nogroup /app/_build/prod/rel/jiraathome ./
USER nobody
EXPOSE 4000
CMD ["bin/jiraathome", "start"]
