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

main_regions="
us-east-1
eu-west-1
us-west-1
ap-southeast-1
ap-northeast-1
us-west-2
sa-east-1
ap-southeast-2
eu-central-1
ap-northeast-2
ap-south-1
us-east-2
ca-central-1
eu-west-2
eu-west-3
ap-northeast-3
eu-north-1
"

cn_regions="
cn-north-1
cn-northwest-1
"

gov_regions="
us-gov-east-1
us-gov-west-1
"

publish_to_ecr() {
	docker tag ${1} ${2}
	ecs-cli push ${2} --region ${3} --registry-id ${4}
}

verify_ecr() {
	ecs-cli pull ${1} --region ${2}
}

make_repo_public() {
	 aws ecr set-repository-policy --repository-name aws-for-fluent-bit --policy-text file://public_repo_policy.json  --region ${1}
}

FLUENT_BIT_VERSION=$(cat ../FLUENT_BIT_VERSION)

if [ "${1}" = "aws" ]; then
	for region in ${main_regions}; do
		publish_to_ecr amazon/aws-for-fluent-bit:latest "906394416424.dkr.${region}.amazonaws.com/aws-for-fluent-bit:latest" ${region}
		publish_to_ecr amazon/aws-for-fluent-bit:latest "906394416424.dkr.${region}.amazonaws.com/aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region}
		make_repo_public ${region}
	done
fi

if [ "${1}" = "aws-cn" ]; then
	for region in ${cn_regions}; do
		publish_to_ecr amazon/aws-for-fluent-bit:latest "128054284489.dkr.${region}.amazonaws.com/aws-for-fluent-bit:latest" ${region}
		publish_to_ecr amazon/aws-for-fluent-bit:latest "128054284489.dkr.${region}.amazonaws.com/aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region}
		make_repo_public ${region}
	done
fi

if [ "${1}" = "aws-us-gov" ]; then
	for region in ${gov_regions}; do
		publish_to_ecr amazon/aws-for-fluent-bit:latest "TODO.dkr.${region}.amazonaws.com/aws-for-fluent-bit:latest" ${region}
		publish_to_ecr amazon/aws-for-fluent-bit:latest "TODO.dkr.${region}.amazonaws.com/aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region}
		make_repo_public ${region}
	done
fi

if [ "${1}" = "hkg" ]; then
	publish_to_ecr amazon/aws-for-fluent-bit:latest "449074385750.dkr.ap-east-1.amazonaws.com/aws-for-fluent-bit:latest" ap-east-1
	publish_to_ecr amazon/aws-for-fluent-bit:latest "449074385750.dkr.ap-east-1.amazonaws.com/aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ap-east-1
	make_repo_public ap-east-1
fi

if [ "${1}" = "gamma" ]; then
	publish_to_ecr amazon/aws-for-fluent-bit:latest aws-for-fluent-bit:latest us-west-2 626332813196
	publish_to_ecr amazon/aws-for-fluent-bit:latest "aws-for-fluent-bit:${FLUENT_BIT_VERSION}" us-west-2 626332813196
	make_repo_public us-west-2
fi
