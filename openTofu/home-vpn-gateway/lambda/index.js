const { EC2Client, StartInstancesCommand, StopInstancesCommand, DescribeInstancesCommand } = require('@aws-sdk/client-ec2');

const ec2Client = new EC2Client({ region: process.env.AWS_REGION });

const ACTION_START = 'start';
const ACTION_STOP = 'stop';
const ACTION_STATUS = 'status';

const ACTIVE_STATES = ['running', 'starting'];
const INACTIVE_STATES = ['stopped', 'stopping'];

exports.handler = async (event, context) => {

  const instanceId = process.env.INSTANCE_ID;
  let body;

  // Parse the incoming request body
  try {

    body = JSON.parse(event.body);

  } catch (error) {

    return buildResponse(400, {
      message: 'Invalid JSON body',
    });
  }

  // Check if 'action' key is present
  if (!body.action) {

    return buildResponse(400, {
      message: 'Missing action key',
    });
  }

  try {

    // Get current status
    const status = await getInstanceStatus(ec2Client, instanceId);

    if (!status) {

      return buildResponse(500, {
        message: 'Instance status cannot be retrieved or it\'s unknown',
      });
    }

    const action = body.action;

    if (action === ACTION_START) {

      if (ACTIVE_STATES.includes(status)) {

        return buildResponse(200, {
          status,
          message: 'Instance is started or about to start',
        });
      }

      const startCommand = new StartInstancesCommand({ InstanceIds: [instanceId] });
      await ec2Client.send(startCommand);

      return buildResponse(202, {
        message: 'Instance start requested',
      });

    } else if (action === ACTION_STOP) {

      if (INACTIVE_STATES.includes(status)) {

        return buildResponse(200, {
          status,
          message: 'Instance is stopped or about to stop',
        });
      }

      const stopCommand = new StopInstancesCommand({ InstanceIds: [instanceId] });
      await ec2Client.send(stopCommand);

      return buildResponse(202, {
        message: 'Instance stop requested',
      });

    } else if (action === ACTION_STATUS) {

      return buildResponse(200, {
        status,
        message: `Instance is ${status}`,
      });
    }

    return buildResponse(400, {
      status,
      message: 'Invalid action'
    });

  } catch (error) {

    return buildResponse(500, {
      error,
      message: `Error executing action: ${error.message}`,
    });
  }
};

/**
 * Retrieves given instance current status or null
 * 
 * @param {*} ec2Client 
 * @param {*} instanceId 
 * @returns 
 */
const getInstanceStatus = async (ec2Client, instanceId) => {

  const describeCommand = new DescribeInstancesCommand({ InstanceIds: [instanceId] });
  const response = await ec2Client.send(describeCommand);
  const reservations = response.Reservations || [];

  if (reservations.length === 0) {
    return null;
  }

  const instance = reservations[0].Instances[0];

  return instance.State?.Name || null;
};

/**
 * Formats actual API responses to AWS Gateway format.
 * 
 * @param {*} code 
 * @param {*} body 
 * @returns 
 */
const buildResponse = (code, body) => {

  return {
    statusCode: code,
    body: JSON.stringify(body),
  }
}
