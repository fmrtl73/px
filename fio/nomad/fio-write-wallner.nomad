job "fio-write" {
  datacenters = ["dc1"]
  type        = "service"

  group "fio-write" {
    count = 1

    task "fio-write" {
      driver = "docker"
      env {
          REMOTEFILES = "https://gist.githubusercontent.com/wallnerryan/cb8f9946a6fb9bdc0aabd403d9550e08/raw/31308d8139718901c1b53c9dea33526cf591881d/seqwrite.fio"
          JOBFILES = "seqwrite.fio"
          PLOTNAME = "seqwrite"
      }      
      config {
        image = "wallnerryan/fiotools-aio"
        port_map {
	  ui = 8000 
	}
        volumes = [
          "name=test-volume,size=12,repl=3:/myvol"
        ]
        volume_driver = "pxd"
      }

      resources {
	cpu = 250
	memory = 512
	network {
	  port "ui" {}
	}
      }
      service {
	name = "fio-write"
	port = "ui"

	check {
	  type = "tcp"
	  interval = "10s"
	  timeout = "2s"
	}
      }
    }
  }
}
