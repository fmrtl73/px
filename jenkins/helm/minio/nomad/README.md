The minio.nomad job deploys a single instance of Minio. To use this instance of Minio as the S3 backup destination for Portworx you will have to run the following command with the correct arguments:

```pxctl cred create --provider s3 --s3-access-key AKIAIOSFODNN7EXAMPLE --s3-secret-key wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY --s3-region us-east-1 --s3-endpoint http://<IP-WHERE-ALLOC-RUNNING>:9000 minio```
