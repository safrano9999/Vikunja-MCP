# syntax=docker/dockerfile:1.7

ARG VIKUNJA_IMAGE=docker.io/vikunja/vikunja:2.5.0@sha256:22df4c1bc8843c28d383bc5f52b59e7b601bf5f6560b36b29c0a500833c77fa3
ARG NODE_IMAGE=docker.io/library/node:24.18.1-alpine@sha256:f70403e87646dc51b45295f4b8b70cdad0b63d2297c4c9899119b03f7af7a6b3

FROM ${VIKUNJA_IMAGE} AS vikunja

FROM ${NODE_IMAGE} AS builder
ARG VIKUNJA_MCP_REVISION=a42e1c2a3bd2b694e79a944fba5153970157b19d
ARG SUPERGATEWAY_REVISION=973c4595250dcd59da83c12c4f11ff653b6cd4f0
RUN apk add --no-cache git python3 make g++

WORKDIR /src/vikunja-mcp
RUN git init \
    && git remote add origin https://github.com/democratize-technology/vikunja-mcp.git \
    && git fetch --depth=1 origin "${VIKUNJA_MCP_REVISION}" \
    && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "${VIKUNJA_MCP_REVISION}" \
    && npm ci \
    && npm run build \
    && npm prune --omit=dev

WORKDIR /src/supergateway
RUN git init \
    && git remote add origin https://github.com/supercorp-ai/supergateway.git \
    && git fetch --depth=1 origin "${SUPERGATEWAY_REVISION}" \
    && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "${SUPERGATEWAY_REVISION}"
COPY patches/supergateway-bearer.patch /tmp/supergateway-bearer.patch
RUN git apply --unidiff-zero --check /tmp/supergateway-bearer.patch \
    && git apply --unidiff-zero /tmp/supergateway-bearer.patch \
    && npm ci \
    && npm run build \
    && npm prune --omit=dev

FROM ${NODE_IMAGE}
RUN apk add --no-cache ca-certificates tini \
    && mkdir -p /app/vikunja/files /opt/vikunja-mcp /opt/supergateway \
    && chown -R 1000:1000 /app/vikunja /opt/vikunja-mcp /opt/supergateway
COPY --from=vikunja --chown=1000:1000 /app/vikunja/vikunja /app/vikunja/vikunja
COPY --from=builder --chown=1000:1000 /src/vikunja-mcp/dist /opt/vikunja-mcp/dist
COPY --from=builder --chown=1000:1000 /src/vikunja-mcp/node_modules /opt/vikunja-mcp/node_modules
COPY --from=builder --chown=1000:1000 /src/vikunja-mcp/package.json /opt/vikunja-mcp/package.json
COPY --from=builder --chown=1000:1000 /src/supergateway/dist /opt/supergateway/dist
COPY --from=builder --chown=1000:1000 /src/supergateway/node_modules /opt/supergateway/node_modules
COPY --from=builder --chown=1000:1000 /src/supergateway/package.json /opt/supergateway/package.json
COPY --chown=1000:1000 --chmod=0755 entrypoint.sh /usr/local/bin/vikunja-mcp-entrypoint

LABEL org.opencontainers.image.title="Vikunja MCP" \
      org.opencontainers.image.description="Vikunja 2.5.0 with a bearer-scoped Streamable HTTP MCP bridge" \
      org.opencontainers.image.source="https://github.com/safrano9999/Vikunja-MCP" \
      org.opencontainers.image.licenses="AGPL-3.0-and-MIT" \
      org.opencontainers.image.base.name="docker.io/vikunja/vikunja:2.5.0" \
      org.opencontainers.image.base.digest="sha256:22df4c1bc8843c28d383bc5f52b59e7b601bf5f6560b36b29c0a500833c77fa3"

ENV NODE_ENV=production \
    VIKUNJA_SERVICE_ROOTPATH=/app/vikunja/ \
    VIKUNJA_DATABASE_PATH=/tmp/vikunja.db \
    VIKUNJA_PORT=3456 \
    VIKUNJA_MCP_PORT=8000 \
    VIKUNJA_MCP_PATH=/mcp \
    VIKUNJA_API_URL=http://127.0.0.1:3456/api/v1
WORKDIR /app/vikunja
USER 1000
EXPOSE 3456 8000
ENTRYPOINT ["/sbin/tini", "-g", "--", "/usr/local/bin/vikunja-mcp-entrypoint"]
