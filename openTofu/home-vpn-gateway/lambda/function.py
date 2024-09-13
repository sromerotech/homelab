import boto3
import os
import json

ec2 = boto3.client('ec2')

def lambda_handler(event, context):

  instance_id = os.environ['INSTANCE_ID']
  action = event.get('action', 'status')  # Action passed as part of the request body

  if action == 'start':

    ec2.start_instances(InstanceIds=[instance_id])
    return {
      "statusCode": 200, 
      "body": f"Started instance {instance_id}"
    }
  
  elif action == 'stop':

    ec2.stop_instances(InstanceIds=[instance_id])
    return {
      "statusCode": 200, 
      "body": f"Stopped instance {instance_id}"
      }
  
  elif action == 'status':

    response = ec2.describe_instances(InstanceIds=[instance_id])
    reservations = response.get('Reservations', [])
    if not reservations:
      return {
        'statusCode': 404,
        'body': json.dumps({'message': 'Instance not found'})
      }
    
    instance = reservations[0]['Instances'][0]
    instance_status = instance.get('State', {}).get('Name', 'Unknown')
    return {
      "statusCode": 200, 
      "body": instance_status
    }
  
  else:

    return {
      "statusCode": 400, 
      "body": "Invalid action"
    }
