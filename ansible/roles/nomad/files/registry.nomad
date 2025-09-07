job "registry" {
  datacenters = ["home"]
  type = "service"

  group "registry" {
    count = 1

    network {
      port "https" {
        static       = 443
        host_network = "secondary1"
      }
    }

    service {
      name = "registry"
      port = "https"
      tags = [
        "http",
      ]

      check {
        type            = "http"
        protocol        = "https"
        path            = "/"
        interval        = "10s"
        timeout         = "2s"
        tls_skip_verify = true
      }
    }

    task "registry" {
      driver = "docker"

      config {
        image = "registry:2"
        ports = ["https"]
      }

      env {
        REGISTRY_HTTP_ADDR            = "0.0.0.0:${NOMAD_PORT_https}"
        REGISTRY_HTTP_TLS_CERTIFICATE = "/local/tls/live/manicminer.io/fullchain.pem"
        REGISTRY_HTTP_TLS_KEY         = "/local/tls/live/manicminer.io/privkey.pem"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      volume_mount {
        volume      = "certs"
        destination = "/local/tls"
        read_only   = true
      }

      volume_mount {
        volume      = "registry"
        destination = "/var/lib/registry"
        read_only   = false
      }
    }

    volume "certs" {
      type      = "host"
      read_only = true
      source    = "certs"
    }

    volume "registry" {
      type      = "host"
      read_only = false
      source    = "registry"
    }
  }
}
