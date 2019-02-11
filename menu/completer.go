package menu

import (
	"strings"

	"github.com/c-bata/go-prompt"
)

func Completer(d prompt.Document) []prompt.Suggest {
	if d.TextBeforeCursor() == "" {
		return []prompt.Suggest{}
	}
	args := strings.Split(d.TextBeforeCursor(), " ")

	return argumentsCompleter(args)
}

var commands = []prompt.Suggest{
	{Text: "deploy", Description: "deploy applications"},
	{Text: "benchmark", Description: "benchmark applications"},
	{Text: "pre-flight-check", Description: "run checks on your kubernetes cluster to verify that the Portworx install can proceed"},
	{Text: "px", Description: "run portworx tests"},
	// Custom command.
	{Text: "exit", Description: "Exit this program"},
	{Text: "quit", Description: "Exit this program"},
}

func argumentsCompleter(args []string) []prompt.Suggest {
	if len(args) <= 1 {
		return prompt.FilterHasPrefix(commands, "", true)
	}

	first := args[0]
	switch first {
	case "deploy":
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
