#!/usr/bin/env sh

if [ "$SET_CONTAINER_TIMEZONE" = "true" ]; then
  echo "$CONTAINER_TIMEZONE" >/etc/timezone \
  && ln -sf /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata
  echo "Container timezone set to: $CONTAINER_TIMEZONE"
else
  echo "Container timezone not modified"
fi

if [ -z "$STOLON_IP" ]; then
  STOLON_IP=$( hostname -i | awk '{print $1}' )
  echo "IP detected $STOLON_IP"
fi

id=$( echo $EXT_HOSTNAME | awk -F '.' '{ print $1 }' | sed 's/[^a-z0-9\_]/_/g' )
echo $id

/usr/local/bin/stolon-sentinel --cluster-name $STOLON_CLUSTER_NAME \
  --store-backend consul \
  --store-endpoints $CONSUL_HTTP_ADDR &
SS_PID=$!

/usr/local/bin/stolon-proxy --cluster-name $STOLON_CLUSTER_NAME \
  --store-backend consul \
  --store-endpoints $CONSUL_HTTP_ADDR \
  --listen-address 0.0.0.0 \
  --port 5432 &
SP_PID=$!

chown postgres /var/lib/postgresql/data/

gosu postgres /usr/local/bin/stolon-keeper  --cluster-name $STOLON_CLUSTER_NAME \
  --data-dir /var/lib/postgresql/data/ \
  --pg-bin-path /usr/lib/postgresql/9.6/bin/ \
  --pg-repl-password $PG_REPL_PASSWORD \
  --pg-repl-username $PG_REPL_USERNAME \
  --pg-su-password $PG_SU_PASSWORD \
  --store-backend consul \
  --store-endpoints $CONSUL_HTTP_ADDR \
  --uid $id \
  --pg-listen-address $STOLON_IP \
  --pg-port 7432 &
SK_PID=$!

echo "Pids sentinel $SS_PID proxy $SP_PID keeper $SK_PID"

trap "kill $SS_PID ; kill $SP_PID ; kill $SK_PID" TERM INT

while true; do
  kill -0 "$SS_PID"
  if [ "$?" = "0" ]; then
    sleep 5
  else
    echo "Exited sentinel"
    exit
  fi

  kill -0 "$SP_PID"
  if [ "$?" = "0" ]; then
    sleep 5
  else
    echo "Exited proxy"
    exit
  fi

  kill -0 "$SK_PID"
  if [ "$?" = "0" ]; then
    sleep 5
  else
    echo "Exited keeper"
    exit
  fi
done
