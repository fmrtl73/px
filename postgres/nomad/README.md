## How to deploy Postgres on Nomad running Portworx

Make sure you edit the file postgres.nomad to fit your environment:
- Update the `datacenter` field to one defined your Nomad environment
- You need to have access to internet so docker can pull the postgres image. If you have a local docker repository you need to update the file accordingly 
- This example is for testing and proof of concept purposes only so passwords are defined using environment variables. For production environment passwords should be stored securely, for example using Vault

To deploy the run the following in one of your Nomad nodes:

```
nomad job run postgres.nomad
```

This example will run one instance of postgres with a HA Portworx volume (replication factor of 3).

You can inspect the volume running the followoing command from one of the Nomad nodes where Portworx is installed:

```
pxctl volume inspect postgres-data
```
