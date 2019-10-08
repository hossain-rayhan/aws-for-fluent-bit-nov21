import boto3
import json
import sys
import os

"""
This script deletes any resources created in the fluent bit integ tests
"""

LOG_GROUP_NAME = 'fluent-bit-integ-test'

client = boto3.client('logs', region_name=os.environ.get('REGION'))

print('deleting log group: ' + LOG_GROUP_NAME)
client.delete_log_group(logGroupName=LOG_GROUP_NAME)
