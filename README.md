# Node Monitor and Notifier

A bash script that monitors the status of a Namada node and notifies via Telegram if issues are detected or actions are taken.

## Overview

This script checks the status of a Namada node, comparing its block height with a peer node and automatically taking actions (like restarting the node service) if necessary. It sends notifications through Telegram if enabled.

## Features

- Monitors local node status and compares block height with RPC.
- Automatically restarts the node service if it becomes unresponsive or significantly lags behind the peer.
- Sends notifications via Telegram.
- Configurable parameters for node details, Telegram API integration, and monitoring thresholds.

## Configuration

Before running the script, configure the following parameters:

- `NODE_RPC_URL`: URL of the local node's RPC interface.

- `TELEGRAM_NOTIFY_ENABLED`: Enable/disable Telegram notifications.

- `TG_CHAT_ID and TG_BOT_KEY`: Telegram chat ID and bot key for notifications.

- `NODE_ID`: Identifier for the node being monitored.

- `ALERT_DIFFERENCE`: Block height difference threshold for triggering alerts.

- `NODE_RESTART_ENABLED`: Toggle for automatically restarting the node.

- `CHECK_INTERVAL`: Time interval (in seconds) between checks.

- `PEER_RPC_URL`: URL of the peer node's RPC interface.

- `MAX_UNSEEN_BLOCKS`: Threshold for missed block alerts.

## Installation

1. Copy the script to your server where node is running.

2. Make the script executable:

```bash
chmod +x node_monitor.sh
```

3. Edit the script to configure the necessary parameters as per your setup.

```bash
nano node_monitor.sh
```

## Usage

Run the script in the background or as a service:

```bash
./node_monitor.sh &
```

## Dependencies

- `curl`: For making HTTP requests to the node's RPC interface.
- `jq`: For parsing JSON data from RPC responses.
