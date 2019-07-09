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

scripts=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${scripts}"

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

DOCKER_HUB_SECRET="com.amazonaws.ec2.madison.dockerhub.aws-for-fluent-bit.credentials"

publish_to_docker_hub() {
	DRY_RUN="${DRY_RUN:-true}"

	username="$(aws secretsmanager get-secret-value --secret-id $DOCKER_HUB_SECRET --region us-west-2 | jq -r '.SecretString | fromjson.username')"
	password="$(aws secretsmanager get-secret-value --secret-id $DOCKER_HUB_SECRET --region us-west-2 | jq -r '.SecretString | fromjson.password')"

	# Logout when the script exits
	trap cleanup EXIT
	cleanup() {
		    docker logout
	}

	# login to DockerHub
	docker login -u "${username}" --password "${password}"

	# Publish to DockerHub only if $DRY_RUN is set to false
	if [[ "${DRY_RUN}" == "false" ]]; then
		docker tag ${1} ${2}
		docker push ${1}
		docker push ${2}
	else
		echo "DRY_RUN: docker tag ${1} ${2}"
		echo "DRY_RUN: docker push ${1}"
		echo "DRY_RUN: docker push ${2}"
		echo "DRY_RUN is NOT set to 'false', skipping DockerHub update. Exiting..."
	fi

}

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

if [ "${1}" = "publish" ]; then
	if [ "${2}" = "dockerhub" ]; then
		publish_to_docker_hub amazon/aws-for-fluent-bit:latest amazon/aws-for-fluent-bit:${FLUENT_BIT_VERSION}
	fi

	if [ "${2}" = "aws" ]; then
		for region in ${main_regions}; do
			publish_to_ecr amazon/aws-for-fluent-bit:latest aws-for-fluent-bit:latest ${region} 906394416424
			publish_to_ecr amazon/aws-for-fluent-bit:latest "aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region} 906394416424
			make_repo_public ${region}
		done
	fi

	if [ "${2}" = "aws-cn" ]; then
		for region in ${cn_regions}; do
			publish_to_ecr amazon/aws-for-fluent-bit:latest aws-for-fluent-bit:latest ${region} 128054284489
			publish_to_ecr amazon/aws-for-fluent-bit:latest "aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region} 128054284489
			make_repo_public ${region}
		done
	fi

	if [ "${2}" = "aws-us-gov" ]; then
		for region in ${gov_regions}; do
			publish_to_ecr amazon/aws-for-fluent-bit:latest aws-for-fluent-bit:latest ${region} 161423150738
			publish_to_ecr amazon/aws-for-fluent-bit:latest "aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region} 161423150738
			make_repo_public ${region}
		done
	fi

	if [ "${2}" = "hkg" ]; then
		publish_to_ecr amazon/aws-for-fluent-bit:latest aws-for-fluent-bit:latest ap-east-1 449074385750
		publish_to_ecr amazon/aws-for-fluent-bit:latest "aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ap-east-1 449074385750
		make_repo_public ap-east-1
	fi

	if [ "${2}" = "gamma" ]; then
		publish_to_ecr amazon/aws-for-fluent-bit:latest aws-for-fluent-bit:latest us-west-2 626332813196
		publish_to_ecr amazon/aws-for-fluent-bit:latest "aws-for-fluent-bit:${FLUENT_BIT_VERSION}" us-west-2 626332813196
		make_repo_public us-west-2
	fi
fi

if [ "${1}" = "verify" ]; then
	if [ "${2}" = "dockerhub" ]; then
		docker pull amazon/aws-for-fluent-bit:latest
		docker pull amazon/aws-for-fluent-bit:${FLUENT_BIT_VERSION}
	fi
	if [ "${2}" = "aws" ]; then
		for region in ${main_regions}; do
			verify_ecr 906394416424.dkr.ecr.${region}.amazonaws.com/aws-for-fluent-bit:latest ${region}
			verify_ecr "906394416424.dkr.ecr.${region}.amazonaws.com/aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region}
		done
	fi

	if [ "${2}" = "aws-cn" ]; then
		for region in ${cn_regions}; do
			verify_ecr 128054284489.dkr.ecr.${region}.amazonaws.com/aws-for-fluent-bit:latest ${region}
			verify_ecr "128054284489.dkr.ecr.${region}.amazonaws.com/aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region}
		done
	fi

	if [ "${2}" = "aws-us-gov" ]; then
		for region in ${gov_regions}; do
			verify_ecr 161423150738.dkr.ecr.${region}.amazonaws.com/aws-for-fluent-bit:latest ${region}
			verify_ecr "161423150738.dkr.ecr.${region}.amazonaws.com/aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region}
		done
	fi

	if [ "${2}" = "hkg" ]; then
		verify_ecr 449074385750.dkr.ecr.ap-east-1.amazonaws.com/aws-for-fluent-bit:latest ${region}
		verify_ecr "449074385750.dkr.ecr.ap-east-1.amazonaws.com/aws-for-fluent-bit:${FLUENT_BIT_VERSION}" ${region}
	fi

	if [ "${2}" = "gamma" ]; then
		verify_ecr 626332813196.dkr.ecr.us-west-2.amazonaws.com/aws-for-fluent-bit:latest us-west-2
		verify_ecr "626332813196.dkr.ecr.us-west-2.amazonaws.com/aws-for-fluent-bit:${FLUENT_BIT_VERSION}" us-west-2
	fi
fi
