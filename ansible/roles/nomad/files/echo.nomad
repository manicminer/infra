job "echo" {
  datacenters = ["home"]
  group "echo" {
    count = 1

    network {
      port "http" {
        host_network = "primary"
      }
    }

    service {
      name = "echo"
      port = "http"
      tags = [
        "http",
        "proxy",
      ]

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:latest"
        args  = [
          "-listen", ":${NOMAD_PORT_http}",
          "-text", "Echo service listening on port ${NOMAD_PORT_http}",
        ]
        ports = ["http"]
      }

      env {
        deploy_id = uuidv4()
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
