#!/bin/bash

TEST_DIR=$(dirname $(realpath $0))

TEST_FILES=$(find $TEST_DIR -name "test_*.rb")

for TEST_FILE in $TEST_FILES; do
  ruby -Itest $TEST_FILE
done