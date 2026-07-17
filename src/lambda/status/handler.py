import json 
import boto3

cloudwatch = boto3.client("cloudwatch")

def handler(event, context):
    """
    Returns the current state of all CloudWatch alarms prefixed 'chatopsbot-'.
    Used both by the Slack /chatops status command and the dashboard API.
    """
    paginator = cloudwatch.get_paginator("describe_alarms")
    alarms = []

    for page in paginator.paginate(AlarmNamePrefix="chatopsbot-"):
        for alarm in page["MetricAlarms"]:
            alarms.append({
                "name": alarm["AlarmName"],
                "state": alarm["StateValue"],          # OK, ALARM, or INSUFFICIENT_DATA
                "reason": alarm.get("StateReason", ""),
                "updated": alarm["StateUpdatedTimestamp"].isoformat()
            })

    overall = "ALARM" if any(a["state"] == "ALARM" for a in alarms) else "OK"

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "overall_status": overall,
            "alarm_count": len(alarms),
            "alarms": alarms
        } )
    }