if ! screen -list | grep -q 'd10'; then
  echo 'd10 already killed'
  exit 1
else
  echo "killing d10"
fi
. /media/sda1/deployment/ports.sh
screen -S 'd10' -X quit
echo "Checking if d10 still alive..."
lsof -i:$d10