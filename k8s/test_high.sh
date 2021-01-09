#!/bin/bash

export DEVICES_TEST_YAML="$(pwd)/eliot/high.yaml"
export ELIOT_DEVICES=50
source test_base.sh
run
