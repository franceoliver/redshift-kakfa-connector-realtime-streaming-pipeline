#!/usr/bin/env python3

from kafka import KafkaProducer
import csv
import json
import logging
import tomli

# Configuration
with open("parameters.toml", mode="rb") as params:
    config = tomli.load(params)

logging.basicConfig(level=config["general"]["logging_level"])
bootstrap_servers = config["general"]["bootstrap_servers"]
topics = config["general"]["topics"]
raw_path = config["publisher"]["raw_path"]
batch_size = config["publisher"]["batch_size"]
schemas = json.loads(config["schemas"]["schemas"])

def create_producer(bootstrap_servers):
    return KafkaProducer(
        bootstrap_servers=bootstrap_servers,
        key_serializer=lambda k: json.dumps(k).encode('utf-8'),
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )

def send_messages(producer, topic, messages):
    schema = schemas[topic]
    try:
        for message in messages:
            key = {"id": message["id"]}  # Using 'id' as the key
            payload = {"schema": schema, "payload": message}
            producer.send(topic, key=key, value=payload)
        producer.flush()
        logging.info(f"Batch of messages sent to topic '{topic}'.")
    except Exception as e:
        logging.error(f"Failed to send messages to topic '{topic}'. Error: {e}")

def process_files_and_send(producer, topics, batch_size):
    for topic in topics:
        try:
            with open(f"{raw_path}/{topic}.csv", encoding="utf-8-sig") as csvfile:
                csvreader = csv.DictReader(csvfile)
                batch = []

                for rows in csvreader:
                    batch.append(rows)
                    if len(batch) >= batch_size:
                        send_messages(producer, topic, batch)
                        batch = []

                if batch:
                    send_messages(producer, topic, batch)

        except FileNotFoundError:
            logging.error(f"File not found: {raw_path}/{topic}.csv")
        except Exception as e:
            logging.error(f"Error processing file for topic '{topic}': {e}")

if __name__ == "__main__":
    producer = create_producer(bootstrap_servers)

    try:
        process_files_and_send(producer, topics, batch_size)
    finally:
        producer.close()