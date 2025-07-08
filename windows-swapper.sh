#!/usr/bin/env bash
#
# windows-swapper.sh
# Called by Proxmox on VM lifecycle events.
# chmod +x windows-swapper.sh
# attach this as a hook-script to the VMIDs you want to alternate between.
# This will make it so when you shut down specified VM1 then specific VM2 starts and vice versa.
# Args:
#   $1 = VMID
#   $2 = Event name (pre-start, post-stop, etc.)

vmid="$1"
event="$2"

# Only proceed on post-stop (clean shutdown)
if [[ "$event" != "post-stop" ]]; then
  exit 0
fi


# Map the just-stopped VM to its standby partner
if [[ "$vmid" == "100" ]]; then #Edit this VMID
  target="101" #Edit this VMID
elif [[ "$vmid" == "101" ]]; then #Edit this VMID
  target="100" #Edit this VMID
else
  exit 0
fi

# Wait for the VM to be fully stopped
timeout=60
interval=2
elapsed=0

while true; do
  status=$(qm status "$vmid" | awk '{print $2}')
  [[ "$status" == "stopped" ]] && break

  sleep $interval
  elapsed=$((elapsed + interval))
  if (( elapsed >= timeout )); then
    echo "windows-swapper: timeout waiting for VM $vmid to stop" >&2
    exit 1
  fi
done

# Update your Nginx frontend to point at the now-active VM
/usr/local/bin/nginx-frontend.sh "$target"

# Boot the standby VM
qm start "$target"
