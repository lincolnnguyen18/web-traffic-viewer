if screen -list | grep -q "d10"; then
  echo "d10 already started"
  exit 1
else
  echo "starting d10"
fi

. /media/sda1/deployment/ports.sh

# Start node server
screen -dmS 'd10'
screen -S 'd10' -X stuff "node .\n"

echo "Checking if node started..."
lsof -i:$d10

# Build vue client
# yarn build