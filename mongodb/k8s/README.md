### MongoDB Data insert and validate

```
db.spaceships.insertMany([
   // MongoDB adds the _id field with an ObjectId if _id is not present
   {name:'USS Enterprise-D',operator:'Starfleet',type:'Explorer',class:'Galaxy',crew:750,codes:[10,11,12]},
   {name:'USS Prometheus',operator:'Starfleet',class:'Prometheus',crew:4,codes:[1,14,17]},
   {name:'USS Defiant',operator:'Starfleet',class:'Defiant',crew:50,codes:[10,17,19]},
   {name:'IKS Buruk',operator:' Klingon Empire',class:'Warship',crew:40,codes:[100,110,120]},
   {name:'IKS Somraw',operator:' Klingon Empire',class:'Raptor',crew:50,codes:[101,111,120]},
   {name:'Scimitar',operator:'Romulan Star Empire',type:'Warbird',class:'Warbird',crew:25,codes:[201,211,220]},
   {name:'Narada',operator:'Romulan Star Empire',type:'Warbird',class:'Warbird',crew:65,codes:[251,251,220]}
]);
```

Retrieve one spaceship
`db.spaceships.findOne()`

Find all documents and using nice formatting:
`db.spaceships.find().pretty()`

Shows only the names of the ships:
`db.spaceships.find({}, {name:true, _id:false})`

### CLI Snapshot
`pxctl volume snapshot create --name mongo-snap <ID>`

### Drop database
`db.spaceships.drop()`

### Restore from snapshot using CLI
`pxctl volume restore -s mongo-snap <ID>`

### Cluster Migration
`storkctl create migrations -c remotecluster-2 --includeResources --startApplications --namespaces default mongomigration`