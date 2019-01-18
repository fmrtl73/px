job "fio-read" {
  datacenters = ["dc1"]
  type        = "batch"

  group "fio-read" {
    count = 1

    task "fio-read" {
      driver = "docker"
      
      config {
        image = "antonipx/fio"
        args =["--blocksize=64k", 
               "--filename=/mnt/fio.dat", 
               "--ioengine=libaio", 
               "--readwrite=read", 
               "--size=10G", 
               "--name=test", 
               "--direct=1", 
               "--iodepth=128", 
               "--readonly"]

        volumes = [
          "name=test-volume,size=12,repl=3:/mnt"
        ]
        volume_driver = "pxd"
      }
    }
  }
}