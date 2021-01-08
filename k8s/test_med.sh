#!/bin/bash

export DEVICES_TEST_YAML="$(pwd)/eliot/medium.yaml"
export ELIOT_DEVICES=500
source test_base.sh
run
