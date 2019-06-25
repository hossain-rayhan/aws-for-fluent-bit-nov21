#!/bin/bash
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
# 	http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

set -xeuo pipefail

# Normalize to working directory being build root (up one level from ./scripts)
ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
cd "${ROOT}"

# Clone plugins into a temp dir
tmpdir=$(mktemp -d)

git clone --quiet https://github.com/aws/amazon-kinesis-firehose-for-fluent-bit.git $tmpdir/firehose
git clone --quiet https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit.git $tmpdir/cloudwatch

cd $tmpdir/firehose
make
cd $tmpdir/cloudwatch
git fetch && git checkout pr
make

# copy plugin .so files to ./bin
cd "${ROOT}"
mkdir -p ./bin
cp $tmpdir/firehose/bin/firehose.so ./bin
cp $tmpdir/cloudwatch/bin/cloudwatch.so ./bin
