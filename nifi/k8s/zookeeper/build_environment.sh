#! /bin/bash

echo "Building for environment $1"

rm -rf deployment || true


vortex --template templates --output deployment -varpath ./environments/$1.yaml
