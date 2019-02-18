package shell

import (
	"log"
	"strings"

	"github.com/c-bata/go-prompt"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Completer function builds the prompt
func Completer(d prompt.Document) []prompt.Suggest {
	t := d.TextBeforeCursor()
	if t == "" {
		return prompt.FilterHasPrefix(commands, "", true)
	}
	args := strings.Split(t, " ")
	if len(args) == 1 {
		if strings.Index(t, " ") > 0 {
			return argumentsCompleter(args)
		}
		return prompt.FilterHasPrefix(commands, t, true)
	}
	return argumentsCompleter(args)
}

var commands = []prompt.Suggest{
	{Text: "install-px", Description: "install portworx"},
	{Text: "deploy", Description: "deploy applications"},
	{Text: "benchmark", Description: "benchmark applications"},
	{Text: "pre-flight-check", Description: "run checks on your kubernetes cluster to verify that the Portworx install can proceed"},
	{Text: "px", Description: "run portworx tests"},
	{Text: "exit", Description: "exit this program, quit also works"},
}

func argumentsCompleter(args []string) []prompt.Suggest {
	if len(args) <= 1 {
		return prompt.FilterHasPrefix(commands, args[0], true)
	}
	if len(args) == 3 && args[0] == "px" {
		switch args[1] {
		case "install":
		case "connect":
		default:
			suggests := getPVCSuggest()
			return prompt.FilterHasPrefix(suggests, args[2], true)
		}
	}
	first := args[0]
	switch first {
	case "deploy":
		second := args[1]
		if len(args) == 2 {
			subcommands := []prompt.Suggest{
				{Text: "minio", Description: "S3 Compatible Objectstore"},
				{Text: "postgres"},
				{Text: "cassandra"},
				{Text: "elasticsearch"},
				{Text: "mongodb"},
				{Text: "mysql"},
				{Text: "coackroachdb"},
				{Text: "jenkins"},
			}
			return prompt.FilterHasPrefix(subcommands, second, true)
		}
	case "benchmark":
		second := args[1]
		if len(args) == 2 {
			subcommands := []prompt.Suggest{
				{Text: "minio"},
				{Text: "postgres"},
				{Text: "cassandra"},
				{Text: "elasticsearch"},
				{Text: "mongodb"},
				{Text: "mysql"},
				{Text: "coackroachdb"},
				{Text: "jenkins"},
			}
			return prompt.FilterHasPrefix(subcommands, second, true)
		}
	case "px":
		second := args[1]
		if len(args) == 2 {
			subcommands := []prompt.Suggest{
				{Text: "backup"},
				{Text: "backup-status"},
				{Text: "install"},
				{Text: "connect"},
				{Text: "snap"},
				{Text: "restore"},
			}
			return prompt.FilterHasPrefix(subcommands, second, true)
		}
	default:
		return []prompt.Suggest{}
	}
	return []prompt.Suggest{}
}
func getPVCSuggest() []prompt.Suggest {
	api := getClient().CoreV1()
	// setup list options
	listOptions := metav1.ListOptions{}
	pvcs, err := api.PersistentVolumeClaims("default").List(listOptions)
	if err != nil {
		log.Fatal(err)
	}
	if len(pvcs.Items) < 1 {
		return []prompt.Suggest{}
	}

	suggests := make([]prompt.Suggest, 0, len(pvcs.Items))
	for i := 0; i < len(pvcs.Items); i++ {
		suggests = append(suggests, prompt.Suggest{Text: pvcs.Items[i].GetName(), Description: pvcs.Items[i].Spec.VolumeName})
	}
	return suggests
}
