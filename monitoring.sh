#!/bin/bash

# Local Node's RPC URL
NODE_RPC_URL="http://localhost:26657"

# Toggle for push notifications via Telegram
TELEGRAM_NOTIFY_ENABLED=false

# Telegram settings
TG_CHAT_ID="<CHAT_ID>"
TG_BOT_KEY="<BOT_KEY>"

# Monitor settings
NODE_ID="node_01"
ALERT_DIFFERENCE=100
NODE_RESTART_ENABLED=true
CHECK_INTERVAL=900  # 15 minutes
PEER_RPC_URL="https://peer-rpc.com:443"
MAX_UNSEEN_BLOCKS=50
LAST_BLOCK_HEIGHT=0

notify_via_telegram() {
  if [ "$TELEGRAM_NOTIFY_ENABLED" == "false" ]; then
    return
  fi

  local msg=$1
  curl -s -X POST "https://api.telegram.org/bot$TG_BOT_KEY/sendMessage" \
       -d "chat_id=$TG_CHAT_ID" \
       -d "text=$msg"
}

check_peer_availability() {
    curl --output /dev/null --silent --head --fail "$PEER_RPC_URL/status" && return 0 || return 1
}

fetch_node_status() {
  while true; do
    node_status=$(curl -s $NODE_RPC_URL/status)
    if [ -z "$node_status" ]; then
      if [ "$NODE_RESTART_ENABLED" == "true" ]; then
        sudo systemctl restart node_service
        notify_via_telegram "Node $NODE_ID unresponsive, restarted."
      else
        notify_via_telegram "Node $NODE_ID unresponsive, check required."
      fi
      sleep 300
    else
      break
    fi
  done

  while true; do
    if check_peer_availability; then
        local_height=$(echo "$node_status" | jq -r '.result.sync_info.latest_block_height')
        peer_height=$(curl -s "$PEER_RPC_URL/status" | jq -r '.result.sync_info.latest_block_height')

        if [ $(($peer_height - $local_height)) -ge $ALERT_DIFFERENCE ]; then
          if [ "$NODE_RESTART_ENABLED" == "true" ]; then
            sudo systemctl restart node_service
            notify_via_telegram "Node $NODE_ID behind by $(($peer_height - $local_height)) blocks, restarted."
            sleep 600
          else
            notify_via_telegram "Node $NODE_ID behind by $(($peer_height - $local_height)) blocks."
            break
          fi
        else
          break
        fi
    else
        echo "Peer RPC not available, skipping block height check."
        break
    fi
  done
}

monitor_validator_activity() {
  local block=$1
  local missed=0
  local consec_missed=0
  local max_consec_missed=0

  for (( i=block; i>block-300 && i>LAST_BLOCK_HEIGHT; i-- )); do
    local sigs=$(curl -s "$PEER_RPC_URL/block?height=$i" | jq -r '.result.block.last_commit.signatures[].validator_address')
    if ! echo "$sigs" | grep -q "$validator_address"; then
      missed=$((missed+1))
      consec_missed=$((consec_missed+1))
      max_consec_missed=$((max_consec_missed < consec_missed ? consec_missed : max_consec_missed))
    else
      consec_missed=0
    fi
  done

  LAST_BLOCK_HEIGHT=$block

  if [ $missed -gt $MAX_UNSEEN_BLOCKS ]; then
    notify_via_telegram "$NODE_ID missed $missed of the last 300 blocks, max consecutive missed: $max_consec_missed"
  fi
}

monitor_node() {
  fetch_node_status
  validator_info=$(curl -s $NODE_RPC_URL/status | jq -sr '.[].result.validator_info')
  block_height=$(echo "$node_status" | jq -r '.result.sync_info.latest_block_height')

  if [ "$block_height" -gt 0 ]; then
    monitor_validator_activity "$block_height"
  fi
}

while true; do
  monitor_node
  sleep $CHECK_INTERVAL
done
