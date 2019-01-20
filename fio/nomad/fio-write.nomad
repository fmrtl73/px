job "fio-write" {
  datacenters = ["dc1"]
  type        = "batch"

  group "fio-write" {
    count = 1

    task "fio-write" {
      driver = "docker"
      
      config {
        image = "antonipx/fio"
        
        args =["--blocksize=64k", 
               "--filename=/mnt/fio.dat", 
               "--ioengine=libaio", 
               "--readwrite=write",  
               "--size=10G", 
               "--name=test", 
               "--direct=1", 
               "--iodepth=128", 
               "--end_fsync=1"]

        volumes = [
          "name=test-volume,size=12,repl=3:/mnt"
        ]
        volume_driver = "pxd"
      }
    }
  }
}