export REGION="us-west-2"

export PROJECT_ROOT="$(pwd)"

test_cloudwatch() {
	# Tag is used to name the log stream; each test run has a unique (random) log stream name
	export TAG=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 10)
	docker-compose --file ./integ/test_cloudwatch/docker-compose.yml build
	docker-compose --file ./integ/test_cloudwatch/docker-compose.yml up --abort-on-container-exit
	sleep 10
	# Validate that log data is present in CW
	docker-compose --file ./integ/test_cloudwatch/docker-compose.validate.yml build
	docker-compose --file ./integ/test_cloudwatch/docker-compose.validate.yml up --abort-on-container-exit
}

clean_up() {
	# Clean up resources that were created in the test
	docker-compose --file ./integ/docker-compose.clean.yml build
	docker-compose --file ./integ/docker-compose.clean.yml up --abort-on-container-exit
}

if [ "${1}" = "cloudwatch" ]; then
	test_cloudwatch
	clean_up
fi

if [ "${1}" = "clean" ]; then
	clean_up
fi
