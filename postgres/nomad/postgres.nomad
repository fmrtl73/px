job "postgres-server" {
  datacenters = ["dc1"]
  type        = "service"

  group "postgres-server" {
    count = 1

    task "postgres-server" {
      driver = "docker"

      env {
          "POSTGRES_USER" = "pgbench"
          "PGUSER" = "pgbench"
          "POSTGRES_PASSWORD" = "superpostgres"
          "PGBENCH_PASSWORD" = "superpostgres"
          "PGDATA" = "/var/lib/postgresql/data/pgdata"
      }
      
      config {
        image = "postgres:9.5"

        port_map {
          db = 5432
        }


        volumes = [
          "name=postgres-data,size=10,repl=3:/var/lib/postgresql/data"
        ]
        volume_driver = "pxd"
      }

      resources {
        cpu    = 250
        memory = 512
        network {
          port "db" {}
        }
      }

      service {
        name = "postgres-server"
        port = "db"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
