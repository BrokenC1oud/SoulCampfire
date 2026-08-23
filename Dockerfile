# syntax=docker/dockerfile:1

FROM docker.io/library/debian:bookworm-slim AS build

ARG ZIG_VERSION=0.16.0

RUN apt-get update \
    && apt-get install --no-install-recommends --yes ca-certificates curl xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/zig \
    && curl -fsSL "https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" \
        -o /tmp/zig.tar.xz \
    && tar -xJ --strip-components=1 -f /tmp/zig.tar.xz -C /opt/zig \
    && rm /tmp/zig.tar.xz

ENV PATH="/opt/zig:${PATH}"

WORKDIR /src
COPY build.zig build.zig.zon ./
COPY src ./src

RUN zig build

FROM docker.io/library/debian:bookworm-slim AS runtime

RUN groupadd --system --gid 10001 soulcampfire \
    && useradd --system --uid 10001 --gid 10001 --home-dir /app --no-create-home soulcampfire \
    && mkdir -p /app/data \
    && chown -R soulcampfire:soulcampfire /app

WORKDIR /app
COPY --from=build /src/zig-out/bin/SoulCampfire /app/SoulCampfire

ENV ZIG_GLOBAL_CACHE_DIR=/tmp/zig-cache
EXPOSE 5700
VOLUME ["/app/data"]
USER soulcampfire

ENTRYPOINT ["/app/SoulCampfire"]
