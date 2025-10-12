job "haproxy" {
  region      = "global"
  datacenters = ["home"]
  type        = "service"

  group "haproxy" {
    count = 1

    network {
      port "http" {
        host_network = "primary"
        static       = 80
      }

      port "https" {
        host_network = "primary"
        static       = 443
      }

      port "haproxy_ui" {
        host_network = "primary"
        static       = 1936
      }
    }

    service {
      name = "haproxy"
      tags = [
        "http",
      ]

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }

      check {
        name     = "alive"
        type     = "tcp"
        port     = "https"
        interval = "10s"
        timeout  = "5s"
      }
    }

    task "haproxy" {
      driver = "docker"

      config {
        image        = "haproxy:2.0"
        #network_mode = "host"
        ports = ["http", "https", "haproxy_ui"]

        volumes = [
          "local/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg",
        ]
      }

      template {
        data = <<EOF
global
   tune.ssl.default-dh-param 2048

defaults
   mode http
   timeout connect 5000
   timeout check 5000
   timeout client 30000
   timeout server 30000

frontend stats
   bind *:{{ env "NOMAD_PORT_haproxy_ui" }}
   stats uri /
   stats show-legends
   no log

frontend http_front
   bind *:{{ env "NOMAD_PORT_http" }}
   bind *:{{ env "NOMAD_PORT_https" }} ssl crt /local/tls/live/manicminer.io/combined.pem
   http-request set-header X-Forwarded-Proto https if { ssl_fc }
   http-request redirect scheme https unless { ssl_fc }
{{ range $tag, $services := services | byTag }}{{ if eq $tag "proxy" }}{{ range $service := $services }}{{ if ne .Name "haproxy" }}
   acl host_{{ .Name }} hdr(host) -i {{ .Name }}.manicminer.io
   use_backend {{ .Name }} if host_{{ .Name }}
{{ end }}{{ end }}{{ end }}{{ end }}

{{ range $tag, $services := services | byTag }}{{ if eq $tag "proxy" }}{{ range $service := $services }}{{ if ne .Name "haproxy" }}
backend {{ .Name }}
    balance roundrobin
    server-template {{ .Name }} 10 _{{ .Name }}._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check
{{ end }}{{ end }}{{ end }}{{ end }}

resolvers consul
   nameserver consul 172.17.0.1:8600
   accepted_payload_size 8192
   hold valid 5s

EOF
        destination = "local/haproxy.cfg"
        change_mode = "restart"

        # Not working due to https://github.com/hashicorp/nomad/issues/5459
        #change_mode   = "signal"
        #change_signal = "SIGHUP"
      }

      resources {
        cpu    = 400
        memory = 256
      }

      volume_mount {
        volume      = "certs"
        destination = "/local/tls"
        read_only   = true
      }
    }

    volume "certs" {
      type      = "host"
      read_only = true
      source    = "certs"
    }
  }
}
