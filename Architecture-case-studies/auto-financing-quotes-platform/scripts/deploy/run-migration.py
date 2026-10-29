"""User-invoked deployment step; never run automatically by Terraform."""
import json
import subprocess
import argparse
from pathlib import Path
import boto3


def main():
    parser = argparse.ArgumentParser(description="Run the one-off AWS migration task.")
    parser.add_argument("--region", required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    result = subprocess.run(["terraform", f"-chdir={root / 'infra' / 'stacks' / 'regional'}", "output", "-json"], check=True, capture_output=True, text=True)
    output = json.loads(result.stdout)
    get = lambda key: output[key]["value"]
    ecs = boto3.client("ecs", region_name=args.region)
    response = ecs.run_task(cluster=get("cluster_name"), taskDefinition=get("migration_task_definition"),
        launchType="FARGATE", count=1, networkConfiguration={"awsvpcConfiguration": {
            "subnets": get("private_subnets"), "securityGroups": [get("compute_security_group")], "assignPublicIp": "DISABLED"}})
    if response.get("failures") or not response.get("tasks"):
        raise SystemExit("Migration task failed to start: " + json.dumps(response.get("failures", [])))
    arn = response["tasks"][0]["taskArn"]
    print("Waiting for migration task:", arn)
    ecs.get_waiter("tasks_stopped").wait(cluster=get("cluster_name"), tasks=[arn])
    task = ecs.describe_tasks(cluster=get("cluster_name"), tasks=[arn])["tasks"][0]
    containers = task.get("containers", [])
    if not containers or any(item.get("exitCode") != 0 for item in containers):
        raise SystemExit("Migration failed; inspect /drivequote/<project>/migration logs. Do not enable runtime.")
    print("Migration succeeded. You can now plan enable_runtime=true.")


if __name__ == "__main__":
    main()
