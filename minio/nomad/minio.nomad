job "minio" {
  datacenters = ["dc1"]

  type = "service"

  update {
    max_parallel = 1
  }

  group "minio" {
    count = 1 

    restart {
      attempts = 3
      delay    = "30s"
      interval = "2m"
      mode = "delay"
    }

    task "minio" {
      driver = "docker"

      config {
        image = "minio/minio:latest"
        args = [
          "server",
          "/var/lib/minio/data"
        ]
        network_mode = "host"
        port_map = {
          minio = 9000
        }
        volumes = [
          "name=minio-data,size=20,repl=3:/var/lib/minio/data"
        ]
        volume_driver = "pxd"
      }

      template {
        data = <<EOH
        MINIO_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE"
        MINIO_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        EOH

        destination = "secrets/file.env"
        env         = true
      }


      service {
        port = "minio"

        tags = [
          "minio"
        ]
      }

      resources {
        cpu    = 500
        memory = 256

        network {
          mbits = 10
          port "minio" {
            static = 9000
          }
        }
      }
    }
  }
}
