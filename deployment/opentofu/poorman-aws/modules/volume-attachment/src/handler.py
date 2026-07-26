import logging
import os
import time

import boto3

AUTOSCALING = boto3.client("autoscaling")
EC2 = boto3.client("ec2")
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

ASG_NAME = os.environ["ASG_NAME"]
DEVICE_NAME = os.environ["DEVICE_NAME"]
VOLUME_ID = os.environ["VOLUME_ID"]


def heartbeat(detail):
    AUTOSCALING.record_lifecycle_action_heartbeat(
        LifecycleHookName=detail["LifecycleHookName"],
        AutoScalingGroupName=detail["AutoScalingGroupName"],
        LifecycleActionToken=detail["LifecycleActionToken"],
        InstanceId=detail["EC2InstanceId"],
    )


def complete(detail, result):
    AUTOSCALING.complete_lifecycle_action(
        LifecycleHookName=detail["LifecycleHookName"],
        AutoScalingGroupName=detail["AutoScalingGroupName"],
        LifecycleActionToken=detail["LifecycleActionToken"],
        InstanceId=detail["EC2InstanceId"],
        LifecycleActionResult=result,
    )


def instance_state(instance_id):
    response = EC2.describe_instances(InstanceIds=[instance_id])
    reservations = response.get("Reservations", [])
    if not reservations or not reservations[0].get("Instances"):
        return "terminated"
    return reservations[0]["Instances"][0]["State"]["Name"]


def wait_for_volume_state(expected, detail, attempts=90):
    for _ in range(attempts):
        volume = EC2.describe_volumes(VolumeIds=[VOLUME_ID])["Volumes"][0]
        if volume["State"] == expected:
            return volume
        heartbeat(detail)
        time.sleep(5)
    raise TimeoutError(f"{VOLUME_ID} did not reach state {expected}")


def handler(event, _context):
    detail = event["detail"]
    instance_id = detail["EC2InstanceId"]

    if detail["AutoScalingGroupName"] != ASG_NAME:
        raise ValueError("event belongs to an unexpected Auto Scaling group")

    volume = EC2.describe_volumes(VolumeIds=[VOLUME_ID])["Volumes"][0]
    attachments = volume.get("Attachments", [])

    for attachment in attachments:
        attached_instance = attachment["InstanceId"]
        if attached_instance == instance_id:
            LOGGER.info("%s is already attached to %s", VOLUME_ID, instance_id)
            complete(detail, "CONTINUE")
            return {"status": "already-attached"}

        state = instance_state(attached_instance)
        if state not in {"stopped", "stopping", "shutting-down", "terminated"}:
            raise RuntimeError(
                f"refusing to detach {VOLUME_ID} from {attached_instance} in state {state}"
            )

        LOGGER.info("detaching %s from former instance %s", VOLUME_ID, attached_instance)
        EC2.detach_volume(
            VolumeId=VOLUME_ID,
            InstanceId=attached_instance,
            Force=False,
        )
        wait_for_volume_state("available", detail)

    heartbeat(detail)
    LOGGER.info("attaching %s to %s as %s", VOLUME_ID, instance_id, DEVICE_NAME)
    EC2.attach_volume(
        Device=DEVICE_NAME,
        InstanceId=instance_id,
        VolumeId=VOLUME_ID,
    )
    wait_for_volume_state("in-use", detail)
    EC2.create_tags(
        Resources=[VOLUME_ID],
        Tags=[{"Key": "AttachedInstanceId", "Value": instance_id}],
    )
    complete(detail, "CONTINUE")
    return {"status": "attached", "instance_id": instance_id, "volume_id": VOLUME_ID}
