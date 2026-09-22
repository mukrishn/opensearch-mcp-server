# OpenSearch MCP Server — streaming HTTP image for OpenShift / Kubernetes
FROM python:3.12-slim AS builder

WORKDIR /build
COPY pyproject.toml README.md LICENSE.txt NOTICE.txt ./
COPY src ./src

RUN pip install --no-cache-dir --prefix=/install .

FROM python:3.12-slim

RUN useradd --create-home --uid 1001 --shell /sbin/nologin mcp

COPY --from=builder /install /usr/local

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    OPENSEARCH_HEADER_AUTH=true \
    OPENSEARCH_DYNAMIC_CONNECTION=false \
    OPENSEARCH_SSL_VERIFY=false

USER 1001
WORKDIR /home/mcp
EXPOSE 9900

ENTRYPOINT ["opensearch-mcp-server-py"]
CMD ["--transport", "stream", "--host", "0.0.0.0", "--port", "9900"]
