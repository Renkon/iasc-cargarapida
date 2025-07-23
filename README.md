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
    server 192.168.1.106:4000 max_fails=1 fail_timeout=30s;
    server 192.168.1.106:4001 max_fails=1 fail_timeout=30s;
    server 192.168.1.106:4002 max_fails=1 fail_timeout=30s;
    server 192.168.1.106:4003 max_fails=1 fail_timeout=30s;
}

server {
    listen 4100;

    location / {
        # Manejo de OPTIONS (preflight CORS)
        if ($request_method = OPTIONS) {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
            add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
            add_header 'Access-Control-Max-Age' 1728000 always;
            add_header 'Content-Length' 0;
            add_header 'Content-Type' 'text/plain; charset=UTF-8';
            return 204;
        }

        # Headers para todas las demás requests
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;

        proxy_pass http://backend;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream_tries 4;

        proxy_connect_timeout 100ms;
        proxy_read_timeout 300ms;
        proxy_send_timeout 300ms;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ws {
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_next_upstream error timeout invalid_header http_502 http_503 http_504;
        proxy_next_upstream_tries 4;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 300ms;
        proxy_read_timeout 7d;
        proxy_send_timeout 7d;

        proxy_pass http://backend;
    }
}
```
## Diagramas
### Arquitectura
<img width="500" alt="diseño" src="https://github.com/user-attachments/assets/f67d4297-4569-4ab3-9a1c-6d50f7ddd2e6" />

### Secuencia Login
<img width="600" alt="login" src="https://github.com/user-attachments/assets/9096b902-f080-496c-82c1-ae53a538d1f3" />

### Secuencia Alerta
<img width="700" alt="alerta" src="https://github.com/user-attachments/assets/a25cfa26-564a-44da-a41b-b28e08c24150" />

### First approach
<img width="900" alt="Arquitectura - Carga Rapida drawio" src="https://github.com/user-attachments/assets/004929c3-17c0-4376-99d7-2e72e039f546" />



