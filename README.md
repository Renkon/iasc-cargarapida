# IascCargarapida

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `iasc_cargarapida` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:iasc_cargarapida, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/iasc_cargarapida>.

## Proxy / load balancing

Configuration for nginx:

```conf
upstream backend {
    server 192.168.1.106:4000 max_fails=1 fail_timeout=2s;
    server 192.168.1.106:4001 max_fails=1 fail_timeout=2s;
    server 192.168.1.106:4002 max_fails=1 fail_timeout=2s;
    server 192.168.1.106:4003 max_fails=1 fail_timeout=2s;
}

server {
    listen 8080;

    location / {
        proxy_pass http://backend;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream_tries 3;

        proxy_connect_timeout 100ms;
        proxy_read_timeout 300ms;
        proxy_send_timeout 300ms;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
