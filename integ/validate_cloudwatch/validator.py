import boto3
import json
import sys
import os


client = boto3.client('logs', region_name=os.environ.get('REGION'))

def validate_test_case(test_name, log_group, log_stream, validator_func):
    print('RUNNING: ' + test_name)
    response = client.get_log_events(logGroupName=log_group,logStreamName=log_stream)
    # test length
    if len(response['events']) != 1000:
        print(str(len(response['events'])) + ' events found in CloudWatch')
        sys.exit('TEST_FAILURE: incorrect number of log events found')

    counter = 0
    for log in response['events']:
        validator_func(counter, log)
        counter += 1

    print('SUCCESS: ' + test_name)

def vanilla_validator(counter, log):
    event = json.loads(log['message'])
    val = int(event['log'])
    if val != counter:
        print('Expected: ' + str(counter) + '; Found: ' + str(val))
        sys.exit('TEST_FAILURE: found out of order log message')

def log_key_validator(counter, log):
    # TODO: .strip could be unneeded in the future: https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit/issues/14
    val = int(log['message'].strip('\"'))
    if val != counter:
        print('Expected: ' + str(counter) + '; Found: ' + str(val))
        sys.exit('TEST_FAILURE: found out of order log message')


tag = os.environ.get('TAG')
# CW Test Case 1: Simple/Basic Configuration, Log message is JSON
validate_test_case('CW Test 1: Basic Config', 'fluent-bit-integ-test', 'from-fluent-bit-basic-test-' + tag, vanilla_validator)

# CW Test Case 2: tests 'log_key' option, Log message is just the stdout output (a number)
validate_test_case('CW Test 2: log_key option', 'fluent-bit-integ-test', 'from-fluent-bit-log-key-test-' + tag, log_key_validator)
