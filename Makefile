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

all: release

.PHONY: release
release:
	docker build --no-cache -t amazon/aws-for-fluent-bit:latest .

.PHONY: integ-cloudwatch
integ-cloudwatch: release
	./integ/integ.sh cloudwatch

.PHONY: integ-cloudwatch-dev
integ-cloudwatch-dev:
	docker build -t amazon/aws-for-fluent-bit:latest .
	./integ/integ.sh cloudwatch

.PHONY: integ-clean
integ-clean:
	./integ/integ.sh clean

.PHONY: integ-clean-cloudwatch
integ-clean-cloudwatch:
	./integ/integ.sh clean-cloudwatch
