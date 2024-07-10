# redshift-kakfa-connector-realtime-streaming-pipeline
An example repository showing how to leverage Kafka to stream your data and save it to your dwh (Redshift)

## Instructions

1. **Run [kafka-executer.sh](kafka-executer.sh) first:** 
   - This script will stop any running containers, start the required containers, and initialize the subscriber and publisher.
   - Monitor the logs to ensure all parts have been executed correctly and the subscriber is still running correctly.
   - Logs are saved in the `run_logs` directory.

2. **Then run [kafka-redshift-connector-executer.sh](kafka-redshift-connector-executer.sh):**
   - This script will install required packages, set up the Kafka Connect Redshift Sink Connector, and consume messages from the topics that are correctly defined within the [parameters.toml](parameters.toml) schema section.
   - All values will currently be in a string due to the publisher set up. Altering this is beyond the scope of this demo repo.
   - If this script fails, open the files and run each part individually to troubleshoot.

## Troubleshooting

- **Logs:**
  - Logs for `kafka-executer.sh` are saved in the `run_logs` directory.
  - Monitor these logs for any errors or issues.
  
- **Manual Execution:**
  - If `kafka-redshift-connector-executer.sh` fails, execute each command manually to identify the issue.
  - Ensure environment variables are set correctly and required services are running.

## Sources Used

- [Building a Real-Time Data Pipeline](https://medium.com/@nydas/building-a-real-time-data-pipeline-5eff6c6d8a3c)
- [Deploy a Scalable Ad Analytics System in the Cloud with Amazon Redshift](https://redpanda-data.medium.com/deploy-a-scalable-ad-analytics-system-in-the-cloud-with-amazon-redshift-fbbfe9df290c)
