package shell

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/status"
	"k8s.io/apimachinery/pkg/fields"
	"k8s.io/apimachinery/pkg/watch"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/remotecommand"

	api "github.com/libopenstorage/openstorage-sdk-clients/sdk/golang"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Executor is the main point of entry for the app, it takes a command and executes it's associated action.
func Executor(s string) {
	s = strings.TrimSpace(s)
	cmdStrings := strings.Split(s, " ")
	if s == "" {
		return
	} else if s == "quit" || s == "exit" {
		fmt.Println("Bye!")
		os.Exit(0)
		return
	}
	switch cmdStrings[0] {
	case "install-px":
		installPX()
	case "deploy":
		if len(cmdStrings) < 2 {
			fmt.Println("deploy requires an application name")
			return
		}
		deploy("default", cmdStrings[1])
	case "benchmark":
		switch cmdStrings[1] {
		case "postgres":
			podExec("default", "app=postgres", "/usr/bin/psql -c 'create database pxdemo;'")
			podExec("default", "app=postgres", "/usr/bin/pgbench -n -i -s 50 pxdemo;")
			podExec("default", "app=postgres", "/usr/bin/psql pxdemo -c 'select count(*) from pgbench_accounts;'")
		default:
			fmt.Printf("%s benchmark not supported\n", cmdStrings[1])
		}
	case "px":
		if len(cmdStrings) < 2 {
			fmt.Println("deploy requires an application name")
			return
		}
		switch cmdStrings[1] {
		case "connect":
			pxInit()
		case "snap":
			if len(cmdStrings) < 3 {
				fmt.Println("px snap requires an application name")
				return
			}
			pxSnap(cmdStrings[2])
		case "backup":
			if len(cmdStrings) < 3 {
				fmt.Println("px backup requires an PVC name")
				return
			}
			pxBackup(cmdStrings[2])
		case "backup-status":
			if len(cmdStrings) < 3 {
				fmt.Println("px backup-status requires a PVC name")
				return
			}
			pxBackupStatus(cmdStrings[2])
		default:
			fmt.Printf("px %s is not a valid command\n", cmdStrings[1])
		}
	case "pre-flight-check":
		preflight()
	default:
		fmt.Printf("%s is not a supported option", s)
	}
	return
}

func preflight() {
	ns := "default"
	path := filepath.Join(homeDir(), "dev", "px-poc", "pre-flight", "px-pfc-tests")
	kubectlApply(filepath.Join(path, "px-pfc-ds.yaml"))
	// WATCH for modifications made to the Pod after metadata.resourceVersion.
	pods, err := getClient().CoreV1().Pods(ns).List(metav1.ListOptions{LabelSelector: "name=px-pfc"})
	handle(err)
	for i := 0; len(pods.Items) == 0 && i < 10; i++ {
		handle(err)
		time.Sleep(time.Millisecond * 500)
		pods, err = getClient().CoreV1().Pods(ns).List(metav1.ListOptions{LabelSelector: "name=px-pfc"})
	}
	if pods.Items[0].Status.Phase != corev1.PodRunning {
		watcher, err := getClient().CoreV1().Pods(ns).Watch(
			metav1.SingleObject(pods.Items[0].ObjectMeta),
		)
		handle(err)
		for event := range watcher.ResultChan() {
			switch event.Type {
			case watch.Modified:
				pod := event.Object.(*corev1.Pod)

				fmt.Printf(".")
				if pod.Status.Phase == corev1.PodRunning {
					fmt.Printf("Pod %s Running\n", pod.Name)
					watcher.Stop()
					break
				}
			default:
				panic("unexpected event type " + event.Type)
			}
		}
	}
	execCmd("kubectl logs -l name=px-pfc")
	execCmd("kubectl delete -f " + filepath.Join(path, "px-pfc-ds.yaml"))
}

func execCmd(cmdString string) {
	if cmdString == "" {
		return
	}
	command := cmdString[0:strings.Index(cmdString, " ")]
	argString := cmdString[strings.Index(cmdString, " ")+1 : len(cmdString)]
	fmt.Printf("%s %s\n", command, strings.Split(argString, " "))
	cmd := exec.Command(command, strings.Split(argString, " ")...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Println("Something went wrong with " + cmdString)
		log.Fatal(err)
	}
}

var client *kubernetes.Clientset

func getClient() *kubernetes.Clientset {
	if client != nil {
		return client
	}
	var kubeconfig *string
	if home := homeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	}
	flag.Parse()

	// use the current context in kubeconfig
	config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	if err != nil {
		panic(err.Error())
	}

	// create the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}
	client = clientset
	return clientset
}

func homeDir() string {
	if h := os.Getenv("HOME"); h != "" {
		return h
	}
	return os.Getenv("USERPROFILE") // windows
}

func kubectlApply(path string) {
	cmd := exec.Command("kubectl", "apply", "-f", path)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Println("Something went wrong with kubectl apply -f " + path)
		os.Exit(1)
	}
}

func podExec(ns string, selector string, cmd string) {

	clientset := getClient()
	// Instantiate loader for kubeconfig file.
	kubeconfig := clientcmd.NewNonInteractiveDeferredLoadingClientConfig(
		clientcmd.NewDefaultClientConfigLoadingRules(),
		&clientcmd.ConfigOverrides{},
	)
	// Get a rest.Config from the kubeconfig file.  This will be passed into all
	// the client objects we create.
	restconfig, err := kubeconfig.ClientConfig()
	handle(err)
	pods, err := clientset.CoreV1().Pods(ns).List(metav1.ListOptions{LabelSelector: selector})
	handle(err)
	if pods != nil && len(pods.Items) > 0 {
		pod := pods.Items[0]
		req := clientset.CoreV1().RESTClient().
			Post().
			Namespace(pod.Namespace).
			Resource("pods").
			Name(pod.Name).
			SubResource("exec").
			VersionedParams(&corev1.PodExecOptions{
				Container: pod.Spec.Containers[0].Name,
				Command:   []string{"/bin/sh", "-c", cmd},
				Stdout:    true,
				Stderr:    true,
			}, scheme.ParameterCodec)
		exec, err := remotecommand.NewSPDYExecutor(restconfig, "POST", req.URL())
		handle(err)

		exec.Stream(remotecommand.StreamOptions{
			Stdout: os.Stdout,
			Stderr: os.Stderr,
			Tty:    false,
		})
	}
}
func installPX() {
	clientset := getClient()
	pods, err := clientset.CoreV1().Pods("kube-system").List(metav1.ListOptions{LabelSelector: "name=" + "portworx"})
	handle(err)
	if len(pods.Items) == 0 {
		fmt.Printf("Couldn't find portworx pods in kube-system, creating it using kubectl apply %s\n", filepath.Join(homeDir(), "dev", "px-poc", "px-spec.yaml"))

		kubectlApply(filepath.Join(homeDir(), "dev", "px-poc", "px-spec.yaml"))

		// WATCH for modifications made to the Pod after metadata.resourceVersion.
		for pods, err = clientset.CoreV1().Pods("kube-system").List(metav1.ListOptions{LabelSelector: "name=portworx"}); len(pods.Items) == 0; {
			handle(err)
			time.Sleep(time.Millisecond * 500)
			pods, err = clientset.CoreV1().Pods("kube-system").List(metav1.ListOptions{LabelSelector: "name=portworx"})
		}
		fmt.Printf("%s pod %s\n", pods.Items[0].Name, pods.Items[0].Status.Phase)

		watcher, err := clientset.CoreV1().Pods("kube-system").Watch(
			metav1.SingleObject(pods.Items[0].ObjectMeta),
		)
		handle(err)
		for event := range watcher.ResultChan() {
			switch event.Type {
			case watch.Modified:
				pod := event.Object.(*corev1.Pod)

				// If the Pod contains a status condition Ready == True, stop watching.
				for _, cond := range pod.Status.Conditions {
					fmt.Printf("%s pod %s\n", pod.Name, pod.Status.Phase)
					if cond.Type == corev1.PodReady &&
						cond.Status == corev1.ConditionTrue {
						fmt.Printf("Pod Ready\n")
						watcher.Stop()
						break
					}
				}
			default:
				panic("unexpected event type " + event.Type)
			}
		}
	} else {
		fmt.Printf("Portworx is already running in kube-sysgtem namespace, pod name = %s \n", pods.Items[0].GetName())
		podExec("kube-system", "name=portworx", "/opt/pwx/bin/pxctl status")
	}
}
func deploy(ns string, app string) {
	clientset := getClient()
	pods, err := clientset.CoreV1().Pods(ns).List(metav1.ListOptions{LabelSelector: "app=" + app})
	handle(err)
	if len(pods.Items) == 0 {
		fmt.Printf("Couldn't find %s pod in namespace %s, creating it using kubectl apply -f %s \n", app, ns, filepath.Join(homeDir(), "dev", "px-poc", app, "k8s", app+".yaml"))

		kubectlApply(filepath.Join(homeDir(), "dev", "px-poc", app, "k8s", app+".yaml"))

		// WATCH for modifications made to the Pod after metadata.resourceVersion.
		for pods, err = clientset.CoreV1().Pods(ns).List(metav1.ListOptions{LabelSelector: "app=" + app}); len(pods.Items) == 0; {
			handle(err)
			time.Sleep(time.Millisecond * 500)
			pods, err = clientset.CoreV1().Pods(ns).List(metav1.ListOptions{LabelSelector: "app=" + app})
		}
		fmt.Printf("%s pod %s\n", pods.Items[0].Name, pods.Items[0].Status.Phase)

		watcher, err := clientset.CoreV1().Pods(ns).Watch(
			metav1.SingleObject(pods.Items[0].ObjectMeta),
		)
		handle(err)
		for event := range watcher.ResultChan() {
			switch event.Type {
			case watch.Modified:
				pod := event.Object.(*corev1.Pod)

				// If the Pod contains a status condition Ready == True, stop watching.
				for _, cond := range pod.Status.Conditions {
					fmt.Printf("%s pod %s\n", pod.Name, pod.Status.Phase)
					if cond.Type == corev1.PodReady &&
						cond.Status == corev1.ConditionTrue {
						fmt.Printf("Pod Ready\n")
						watcher.Stop()
						break
					}
				}
			default:
				panic("unexpected event type " + event.Type)
			}
		}
	} else {
		fmt.Printf("%s is already running in %s namespace, pod name = %s \n", app, ns, pods.Items[0].GetName())
	}
}

var conn *grpc.ClientConn
var err error

func getPXConn() *grpc.ClientConn {
	if conn != nil {
		return conn
	}
	conn, err = grpc.Dial("192.168.56.71:9020", grpc.WithInsecure())
	if err != nil {
		fmt.Printf("Error: %v", err)
		os.Exit(1)
	}
	return conn
}
func pxInit() {
	// connect to Portworx
	cluster := api.NewOpenStorageClusterClient(getPXConn())
	clusterInfo, err := cluster.InspectCurrent(
		context.Background(),
		&api.SdkClusterInspectCurrentRequest{})
	if err != nil {
		gerr, _ := status.FromError(err)
		fmt.Printf("Error Code[%d] Message[%s]\n",
			gerr.Code(), gerr.Message())
		os.Exit(1)
	}
	fmt.Printf("Connected to Cluster %s\n",
		clusterInfo.GetCluster().GetId())
}
func pxCreateVolume(name string) {
	// Create a 100Gi volume
	volumes := api.NewOpenStorageVolumeClient(getPXConn())
	v, err := volumes.Create(
		context.Background(),
		&api.SdkVolumeCreateRequest{
			Name: "myvol",
			Spec: &api.VolumeSpec{
				Size:    100 * 1024 * 1024 * 1024,
				HaLevel: 3,
			},
		})
	if err != nil {
		gerr, _ := status.FromError(err)
		fmt.Printf("Error Code[%d] Message[%s]\n",
			gerr.Code(), gerr.Message())
		os.Exit(1)
	}
	fmt.Printf("Volume 100Gi created with id %s\n", v.GetVolumeId())
}
func pxCreateCred() string {
	fmt.Println("Setting up Minio Credentials for Portworx")
	// Create Credentials
	var cred string
	creds := api.NewOpenStorageCredentialsClient(getPXConn())
	credsEnum, err := creds.Enumerate(context.Background(), &api.SdkCredentialEnumerateRequest{})
	handle(err)
	fmt.Printf("got enumeration of creds: %s\n", credsEnum.GetCredentialIds())
	if len(credsEnum.GetCredentialIds()) > 0 {
		cred = credsEnum.GetCredentialIds()[0]
		validation, verr := creds.Validate(context.Background(),
			&api.SdkCredentialValidateRequest{
				CredentialId: cred,
			})
		handle(verr)
		fmt.Printf("Performed validation of credID %s, result = %+v\n", cred, validation)
	} else {
		credResponse, credErr := creds.Create(context.Background(),
			&api.SdkCredentialCreateRequest{
				Name: "minio-s3",
				CredentialType: &api.SdkCredentialCreateRequest_AwsCredential{
					AwsCredential: &api.SdkAwsCredentialRequest{
						AccessKey: "MyAccessKey",
						SecretKey: "MySecret",
						Endpoint:  "http://minio.px",
						Region:    "dummy-region",
					},
				},
			})
		handle(credErr)
		cred = credResponse.GetCredentialId()
		fmt.Printf("Credentials created with id %s\n", cred)
	}
	return cred
}

var credID string

func getCredID() string {
	fmt.Printf("Getting Cred ID, credID = %s\n", credID)
	if credID == "" {
		credID = pxCreateCred()
	}
	return credID
}
func pxSnap(pvc string) {
	kapi := getClient().CoreV1()
	// setup list options
	listOptions := metav1.ListOptions{
		FieldSelector: fields.OneTermEqualSelector("metadata.name", pvc).String(),
	}
	pvcs, err := kapi.PersistentVolumeClaims("default").List(listOptions)
	if err != nil {
		log.Fatal(err)
	}
	if len(pvcs.Items) < 1 {
		fmt.Printf("Cannot find pvc with name %s", pvc)
	}

	vclient := api.NewOpenStorageVolumeClient(getPXConn())
	vols, err := vclient.EnumerateWithFilters(context.Background(), &api.SdkVolumeEnumerateWithFiltersRequest{
		Locator: &api.VolumeLocator{
			Name: pvcs.Items[0].Spec.VolumeName,
		},
	})
	handle(err)
	if len(vols.GetVolumeIds()) < 1 {
		fmt.Printf("cannot find a volume with name = %s\n", pvc)
		return
	}
	volID := vols.GetVolumeIds()[0]
	snap, err := vclient.SnapshotCreate(
		context.Background(),
		&api.SdkVolumeSnapshotCreateRequest{
			VolumeId: volID,
			Name:     fmt.Sprintf("snap-%v", time.Now().Unix()),
		},
	)
	if err != nil {
		gerr, _ := status.FromError(err)
		fmt.Printf("Error Code[%d] Message[%s]\n",
			gerr.Code(), gerr.Message())
		os.Exit(1)
	}
	fmt.Printf("Snapshot with id %s was create for volume %s\n",
		snap.GetSnapshotId(),
		volID)
}

func pxBackup(pvc string) {
	kapi := getClient().CoreV1()
	// setup list options
	listOptions := metav1.ListOptions{
		FieldSelector: fields.OneTermEqualSelector("metadata.name", pvc).String(),
	}
	pvcs, err := kapi.PersistentVolumeClaims("default").List(listOptions)
	if err != nil {
		log.Fatal(err)
	}
	if len(pvcs.Items) < 1 {
		fmt.Printf("Cannot find pvc with name %s", pvc)
	}
	vclient := api.NewOpenStorageVolumeClient(getPXConn())
	vols, err := vclient.EnumerateWithFilters(context.Background(), &api.SdkVolumeEnumerateWithFiltersRequest{
		Locator: &api.VolumeLocator{
			Name: pvcs.Items[0].Spec.VolumeName,
		},
	})
	handle(err)
	if len(vols.GetVolumeIds()) < 1 {
		fmt.Printf("cannot find a volume with name = %s\n", pvc)
		return
	}
	volID := vols.GetVolumeIds()[0]
	credID := getCredID()
	// Create a backup to a cloud provider of our volume
	cloudbackups := api.NewOpenStorageCloudBackupClient(getPXConn())
	backupCreateResp, err := cloudbackups.Create(context.Background(),
		&api.SdkCloudBackupCreateRequest{
			VolumeId:     volID,
			CredentialId: credID,
		})
	if err != nil {
		gerr, _ := status.FromError(err)
		fmt.Printf("Error Code[%d] Message[%s]\n",
			gerr.Code(), gerr.Message())
		os.Exit(1)
	}
	taskID := backupCreateResp.GetTaskId()
	fmt.Printf("Backup started for volume %s with task id %s\n",
		volID,
		taskID)
	// Now check the status of the backup
	backupStatus, err := cloudbackups.Status(context.Background(),
		&api.SdkCloudBackupStatusRequest{
			VolumeId: volID,
		})
	if err != nil {
		gerr, _ := status.FromError(err)
		fmt.Printf("Error Code[%d] Message[%s]\n",
			gerr.Code(), gerr.Message())
		os.Exit(1)
	}
	for taskID, status := range backupStatus.GetStatuses() {
		// There will be only one value in the map, but we use
		// a for-loop as an example.
		fmt.Printf("Backup status for taskId: %s\n"+
			"Volume: %s\n"+
			"Type: %s\n"+
			"Status: %s\n",
			taskID,
			status.GetSrcVolumeId(),
			status.GetOptype().String(),
			status.GetStatus().String())
	}
}
func pxBackupStatus(pvc string) {
	kapi := getClient().CoreV1()
	// setup list options
	listOptions := metav1.ListOptions{
		FieldSelector: fields.OneTermEqualSelector("metadata.name", pvc).String(),
	}
	pvcs, err := kapi.PersistentVolumeClaims("default").List(listOptions)
	if err != nil {
		log.Fatal(err)
	}
	if len(pvcs.Items) < 1 {
		fmt.Printf("Cannot find pvc with name %s", pvc)
	}
	vclient := api.NewOpenStorageVolumeClient(getPXConn())
	vols, err := vclient.EnumerateWithFilters(context.Background(), &api.SdkVolumeEnumerateWithFiltersRequest{
		Locator: &api.VolumeLocator{
			Name: pvcs.Items[0].Spec.VolumeName,
		},
	})
	handle(err)
	if len(vols.GetVolumeIds()) < 1 {
		fmt.Printf("cannot find a volume with name = %s\n", pvc)
		return
	}
	volID := vols.GetVolumeIds()[0]
	// Now check the status of the backup
	cloudbackups := api.NewOpenStorageCloudBackupClient(getPXConn())
	backupStatus, err := cloudbackups.Status(context.Background(),
		&api.SdkCloudBackupStatusRequest{
			VolumeId: volID,
		})
	if err != nil {
		gerr, _ := status.FromError(err)
		fmt.Printf("Error Code[%d] Message[%s]\n",
			gerr.Code(), gerr.Message())
		os.Exit(1)
	}
	for taskID, status := range backupStatus.GetStatuses() {
		// There will be only one value in the map, but we use
		// a for-loop as an example.
		fmt.Printf("Backup status for taskId: %s\n"+
			"Volume: %s\n"+
			"Type: %s\n"+
			"Status: %s\n",
			taskID,
			status.GetSrcVolumeId(),
			status.GetOptype().String(),
			status.GetStatus().String(),
		)
	}
}

func handle(err error) {
	if err != nil {
		gerr, _ := status.FromError(err)
		fmt.Printf("Error Code[%d] Message[%s]\n",
			gerr.Code(), gerr.Message())
		os.Exit(1)
	}
}
