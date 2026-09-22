# OpenShift deploy — OpenSearch MCP Server (ES MCP–style header auth)

Same pattern as intlab ES MCP: one shared Route, each Cursor client picks the
OpenSearch/ES cluster via HTTP headers.

## Build & push

```bash
cd /path/to/opensearch-mcp-server
podman build -t quay.io/mukrishn/opensearch-mcp-server:latest .
podman push quay.io/mukrishn/opensearch-mcp-server:latest
```

## Deploy

kustomize / split manifests:

```bash
oc apply -k openshift/
```

```bash
oc -n opensearch-mcp rollout status deploy/opensearch-mcp
oc -n opensearch-mcp get route perfscale -o jsonpath='{.spec.host}{"\n"}'
```

Endpoint: `https://perfscale-opensearch-mcp.apps.<cluster>/mcp`  
(Also: `/sse` + `/messages/` for SSE clients; `/health` for probes.)

## Server env (set in Deployment / Secret)

| Env | Value | ES MCP equivalent |
|-----|-------|-------------------|
| `OPENSEARCH_HEADER_AUTH` | `true` | always-on URL override |
| `OPENSEARCH_DYNAMIC_CONNECTION` | `false` | headers only, not tool args |
| `OPENSEARCH_SSL_VERIFY` | `false` | `X-Elasticsearch-Insecure: true` |
| stream `--host 0.0.0.0 --port 9900` | set | HTTP/SSE listener |

`secret.yaml` ships with placeholder `OPENSEARCH_URL` / username / password as the
**default** cluster. Update those on the cluster (not in git). Clients can still
override via headers for other clusters.

Secret updates do not roll pods by themselves. After changing the Secret:

```bash
oc -n opensearch-mcp rollout restart deploy/opensearch-mcp
```

## Cursor headers (not identical to ES MCP)

| ES MCP (`mcp.json`) | OpenSearch MCP |
|---------------------|----------------|
| `X-Elasticsearch-URL: https://user:pass@host` | `opensearch-url: https://host` **+** `Authorization: Basic …` |
| `X-Elasticsearch-Insecure: true` | server `OPENSEARCH_SSL_VERIFY=false` |
| URL `/mcp/sse` | URL `/mcp` (streamable HTTP) |

**Important:** do **not** put `user:pass@` in `opensearch-url`. Caller-supplied URLs strip embedded credentials; auth must be the `Authorization` header.

For header Basic auth, encode credentials locally — never put real credentials in this README or in git.

See `mcp.json.example`.
