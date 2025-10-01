#!/bin/bash

# MCP Inspector Startup Script
# This script starts both the server and client components

set -e

# Default ports
CLIENT_PORT=${CLIENT_PORT:-3000}
SERVER_PORT=${SERVER_PORT:-6277}

# Generate session token if not provided
if [ -z "$MCP_PROXY_AUTH_TOKEN" ]; then
    MCP_PROXY_AUTH_TOKEN=$(openssl rand -hex 32)
fi

echo "🚀 Starting MCP Inspector..."
echo "📡 Server will run on port: $SERVER_PORT"
echo "🌐 Client will run on port: $CLIENT_PORT"

# Function to handle cleanup
cleanup() {
    echo "🛑 Shutting down MCP Inspector..."
    kill $SERVER_PID $CLIENT_PID 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Start the server in background
echo "📡 Starting MCP Inspector Server..."
cd /app/server
# Set environment variables for the server
export SERVER_PORT=$SERVER_PORT
export CLIENT_PORT=$CLIENT_PORT
export MCP_PROXY_AUTH_TOKEN=$MCP_PROXY_AUTH_TOKEN
node build/index.js &
SERVER_PID=$!

# Wait for server to start and check if it's ready
echo "⏳ Waiting for server to start..."
sleep 3

# Check if server process is still running
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "❌ Server process failed to start"
    exit 1
fi

# Wait for server to be ready (check if port is listening)
echo "⏳ Waiting for server to be ready..."
for i in {1..10}; do
    if nc -z localhost $SERVER_PORT 2>/dev/null; then
        echo "✅ Server is ready on port $SERVER_PORT"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ Server failed to start on port $SERVER_PORT after 10 attempts"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

# Start the client in background
echo "🌐 Starting MCP Inspector Client..."
cd /app/client
# Set environment variables for the client
export CLIENT_PORT=$CLIENT_PORT
export SERVER_PORT=$SERVER_PORT
export MCP_PROXY_AUTH_TOKEN=$MCP_PROXY_AUTH_TOKEN
export MCP_PROXY_PORT=$SERVER_PORT
node bin/client.js &
CLIENT_PID=$!

# Wait for client to start and check if it's ready
echo "⏳ Waiting for client to start..."
sleep 3

# Check if client process is still running
if ! kill -0 $CLIENT_PID 2>/dev/null; then
    echo "❌ Client process failed to start"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

# Wait for client to be ready (check if port is listening)
echo "⏳ Waiting for client to be ready..."
for i in {1..10}; do
    if nc -z localhost $CLIENT_PORT 2>/dev/null; then
        echo "✅ Client is ready on port $CLIENT_PORT"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ Client failed to start on port $CLIENT_PORT after 10 attempts"
        kill $SERVER_PID $CLIENT_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

echo "✅ MCP Inspector is running!"
echo "🌐 Access the client at: http://localhost:$CLIENT_PORT"
echo "📡 Server API available at: http://localhost:$SERVER_PORT"
echo "🔐 Auth token: $MCP_PROXY_AUTH_TOKEN"
echo ""
echo "💡 The auth token is automatically configured for the client."
echo "   If you need to access the server directly, use:"
echo "   curl -H 'X-MCP-Proxy-Auth: Bearer $MCP_PROXY_AUTH_TOKEN' http://localhost:$SERVER_PORT/config"

# Wait for both processes
wait $SERVER_PID $CLIENT_PID
