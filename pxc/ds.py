import grpc
from openstorage import api_pb2
from openstorage import api_pb2_grpc
from openstorage import connector
from collections import defaultdict
import sys,getopt,time
# No need to setup connection information to your cluster.
# pxc will pass all the required information.
c = connector.Connector()
channel = c.connect()
datastores_byNodeName = defaultdict(list)
datastore_byPool = dict()
nodes_byDatastore = defaultdict(list)
node_ids_byDatastore = defaultdict(list)
node_ids = dict()
node_names = dict()
pool_ids_byNode = dict()
volumes_byDatastore = defaultdict(list)
volume_ids = dict()
volume_names = dict()
volume_replicas= defaultdict(list)

def listDatastoreVolumes(argv):

        for k,v in nodes_byDatastore.items():
            print('datastore {0} is used on the following nodes: {1}'.format(k, v))
            print('     volumes_replicas: ')
            if(volumes_byDatastore[k]):
                for vol in volumes_byDatastore[k]:
                    print('         - {0}'.format(vol))
            else:
                print('         - []')

def initialize():
    try:
        clusters = api_pb2_grpc.OpenStorageClusterStub(channel)
        ic_resp = clusters.InspectCurrent(api_pb2.SdkClusterInspectCurrentRequest())
        nodes = api_pb2_grpc.OpenStorageNodeStub(channel)
        in_resp = nodes.Enumerate(api_pb2.SdkNodeEnumerateRequest())

        for node in in_resp.node_ids :
            ni_resp = nodes.Inspect(api_pb2.SdkNodeInspectRequest(node_id = node))
            node_ids[ni_resp.node.scheduler_node_name]=node
            node_names[node]=ni_resp.node.scheduler_node_name
        for node_name in node_names.values():
            node_i=nodes.Inspect(api_pb2.SdkNodeInspectRequest(node_id = node_ids[node_name]))
            pools = node_i.node.pools
            for pool in pools:
                datastores_byNodeName[node_name].append(pool.labels['px/datastore'])
                nodes_byDatastore[pool.labels['px/datastore']].append(node_name)
                node_ids_byDatastore[pool.labels['px/datastore']].append(node_ids[node_name])
                datastore_byPool[pool.uuid]=pool.labels['px/datastore']
                pool_ids_byNode[node_name]=pool.uuid
        volumes = api_pb2_grpc.OpenStorageVolumeStub(channel)
        v_resp = volumes.Enumerate(api_pb2.SdkVolumeEnumerateRequest())
        for v in v_resp.volume_ids :
            volume_resp = volumes.Inspect(api_pb2.SdkVolumeInspectRequest(volume_id = v))
            replica_sets = volume_resp.volume.replica_sets
            volume_names[v]=volume_resp.labels['pvc']
            volume_ids[volume_resp.labels['pvc']]=v
            for rs in replica_sets:
                for n in rs.nodes:
                    volume_replicas[v].append(node_names[n])
                for p in rs.pool_uuids:
                    if (volume_resp.labels['pvc'] not in volumes_byDatastore[datastore_byPool[p]]):
                        volumes_byDatastore[datastore_byPool[p]].append(volume_resp.labels['pvc'])
    except grpc.RpcError as e:
        print('Failed: code={0} msg={1}'.format(e.code(), e.details()))

# describeVol prints the volume spec.
def describeVol(vol):
    try:
        volumes = api_pb2_grpc.OpenStorageVolumeStub(channel)
        volume_resp = volumes.Inspect(api_pb2.SdkVolumeInspectRequest(volume_id = vol))
        print(volume_resp.volume)
    except grpc.RpcError as e:
        print('Failed describe vol {0}: code={1} msg={2}\n\n'.format(vol,e.code(),e.details()))


# Movel all volume replicas from one datastore to another
def moveAll(fromds,tods):
    for volid in volume_ids.values():
        move(volid,fromds,tods)

# Move a specific volume's replicas from one datastore to another.
def move(volid, fromds,tods):
    to_node_ids = node_ids_byDatastore[tods]
    from_node_ids = node_ids_byDatastore[fromds]
    current_repl_list = list()
    move_from = list()
    move_to = list()
    # get current set of nodes where volume is replicated
    try:
        volumes = api_pb2_grpc.OpenStorageVolumeStub(channel)
        volume_resp = volumes.Inspect(api_pb2.SdkVolumeInspectRequest(volume_id = volid))
        replica_sets = volume_resp.volume.replica_sets
        #build list of current replica nodes
        for rs in replica_sets:
            for n in rs.nodes:
                current_repl_list.append(n)
        # build the list of replicas that need to be moved
        for n in current_repl_list:
            if(n in from_node_ids):
                move_from.append(n)
                # for each replica that is moved there needs to be a node to move it to on the to_node_ids list that is not currently in the replicas list
                for candidate in to_node_ids:
                    if(candidate not in current_repl_list and candidate not in move_to):
                        move_to.append(candidate)
                        break
        # if the number of move from/to don't match we can't perform the move
        if(len(move_from) > len(move_to)):
            print("   - cannot find enough target nodes to replicate to")
        if(len(move_from)==0):
            return
        print('Moving volume {0} from datastore {1} to datastore {2}'.format(volume_names[volid],fromds,tods))
        print(' - volume {0} is replicated on nodes {1}'.format(volume_names[volid], volume_replicas[volid]))
        to_node=''
        # if current repl = 3 perform the move (repl remove + repl add)
        if(len(current_repl_list) == 3):
            for n in move_from:
                print('   - removing replica from node: {0}'.format(node_names[n]))
                ha_update(volid, 2, n)
                to_node=move_to.pop()
                print('   - adding replica to node {0}'.format(node_names[to_node]))
                ha_update(volid, 3,to_node)
        # if current repl = 2 or 1 perform the move (repl add + repl remove)
        else:
            for n in move_from:
                to_node=move_to.pop()
                print('   - adding replica to node {0}'.format(node_names[to_node]))
                ha_update(volid, 3,to_node)
                print('   - removing replica from node: {0}'.format(node_names[n]))
                ha_update(volid, 2, n)

    except grpc.RpcError as e:
        print('Failed get volume {0}: code={1} msg={2}\n\n'.format(volid,e.code(),e.details()))


def ha_update(volid,ha_level, node_id):
    try:
        volumes = api_pb2_grpc.OpenStorageVolumeStub(channel)
        spec = api_pb2.VolumeSpecUpdate(
        )
        spec.ha_level=ha_level
        nodelist = list()
        nodelist.append(node_id)
        spec.replica_set.nodes.extend(nodelist)
        updateReq = api_pb2.SdkVolumeUpdateRequest(
                volume_id = volid,
                labels ={},
                spec = spec
        )
        volumes.Update(updateReq)
        # wait for the sync process to complete
        while True:
            volume_resp = volumes.Inspect(api_pb2.SdkVolumeInspectRequest(volume_id = volid))
            if(volume_resp.volume.runtime_state[0].runtime_state['RuntimeState']=='clean' and
               ha_level == len(volume_resp.volume.runtime_state[0].runtime_state['ReplicaSetCurr'].split())):
                break
            else:
                time.sleep(1)
    except grpc.RpcError as e:
        print('Failed update to vol {0}: code={1} msg={2}\n\n'.format(id,e.code(),e.details()))

def printUsage():
    print('Usage: kubectl pxc script ds.py <command>')
    print('\nCommands:')
    print('  list       List datastores and the volumes they contain')
    print('  move       Move one or more volumes from one datastore to another')

def printUsageMove():
    print('Usage: kubectl pxc script ds.py move <vol> <from-datastore> <to-datastore>')
    print('\nParameters:')
    print('  vol                pvc name, or all to move all volumes')
    print('  from-datastore     name of the datastore to move volume replicas from')
    print('  to-datastore       name of the datastore to move volume replicas to')

def printUsageDescribe():
    print('Usage: kubectl pxc script ds.py describe <vol>')
    print('\nParameters:')
    print('  vol                pvc name')

# Main function
def main(argv):
    if (len(argv) == 0):
        printUsage()
    else:
        commandName = argv[0]
        if(commandName == 'list'):
            initialize()
            listDatastoreVolumes(argv)
        elif(commandName == 'describe'):
            if (len(argv) != 2):
                print('Error wrong number of arguments for move command.\n')
                printUsageDescribe()
                return
            initialize()
            describeVol(volume_ids[argv[1]])

        elif(commandName == 'move'):
            if (len(argv) != 4):
                print('Error wrong number of arguments for move command.\n')
                printUsageMove()
                return
            initialize()
            if(argv[1] == 'all'):
                moveAll(argv[2],argv[3])
            else:
                move(volume_ids[argv[1]],argv[2],argv[3])
        else:
            print('Error: unknown command \"{0}\" for script "ds"\n'.format(argv[0]))
            printUsage()


if __name__ == "__main__":
   main(sys.argv[1:])