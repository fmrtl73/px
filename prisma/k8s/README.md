The artifacts in this folder will allow you to deploy Mysql and Prisma along with an ingress rule for the prisma service.

The data model is configured through the prisma-cm.yaml config map.

The prisma-cli.yaml is a job that deploys the datamodel to the Prisma server.

The ingress rule has been tested with nginx ingress controller and uses a host rule (add prisma.px to your host file and go to http://prisma.px to access to the [graphql playground](https://github.com/prisma-labs/graphql-playground).

Try creating a user:
```
mutation {
  createUser(data: {
    name: "Joe"
  }) {
    id
  }
}
```

And then query for users:
```
query  {
  users {
    name
    id
  }
}
```
