#!/bin/bash

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
echo "Please install ngrok and add it to your PATH."
echo "You can download ngrok from https://ngrok.com/download"
exit 1
fi

# Check if ngrok authentication token is set
if [ -z "$NGROK_AUTH_TOKEN" ]; then
echo "Please set your ngrok authentication token by running:"
echo "export NGROK_AUTH_TOKEN='your_auth_token'"
echo "Replace 'your_auth_token' with your actual ngrok authentication token."
exit 1
fi

# Function to start the Docker container
start_container() {
echo "Starting Windows 11 container..."
docker start windows-container
}

# Function to stop the Docker container
stop_container() {
echo "Stopping Windows 11 container..."
docker stop windows-container
}

# Check command line arguments
if [ "$1" == "start" ]; then
start_container
elif [ "$1" == "stop" ]; then
stop_container
else
echo "Usage: $0 [start|stop]"
exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
echo "Docker not found. Exiting..."
exit 1
fi

# Create a directory to mount as a volume
mkdir -p ~/win_data

# Start the Docker container with a mounted volume
docker run -d --name windows-container -p 3389:3389 -v ~/win_data:/data mcr.microsoft.com/windows:11

# Set up ngrok tunnel for RDP
echo "Setting up ngrok tunnel for RDP..."
ngrok authtoken $NGROK_AUTH_TOKEN
ngrok tcp 3389 &

# Wait for the tunnel to establish
sleep 5

# Get the tunnel address
tunnel_address=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')

echo "ngrok tunnel established for RDP. Access available at: $tunnel_address"

# Run the Windows 11 Docker container
echo "Running the Windows 11 Docker container..."
docker run -it --rm --name windows -p 8006:8006 --device=/dev/kvm --cap-add NET_ADMIN --stop-timeout 120 dockurr/windows
