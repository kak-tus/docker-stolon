#!/usr/bin/env sh

IP=$( hostname -i | awk '{print $1}' )
echo $IP

id=$( echo $EXT_HOSTNAME | awk -F '.' '{ print $1 }' | sed 's/[^a-z\d\_]/_/g' )
echo $id

/usr/local/bin/stolon-sentinel --cluster-name db --store-backend consul \
  --store-endpoints $CONSUL_HTTP_ADDR --listen-address $IP \
  --port 6431 >/proc/1/fd/1 2>/proc/1/fd/2 &
SS_PID=$!

/usr/local/bin/stolon-proxy --cluster-name db --store-backend consul \
  --store-endpoints $CONSUL_HTTP_ADDR --listen-address 0.0.0.0 \
  --port 5432 >/proc/1/fd/1 2>/proc/1/fd/2 &
SP_PID=$!

chown postgres /var/lib/postgresql/data/

gosu postgres /usr/local/bin/stolon-keeper --cluster-name db \
  --data-dir /var/lib/postgresql/data/ \
  --pg-bin-path /usr/lib/postgresql/9.6/bin/ \
  --pg-repl-password $PG_REPL_PASSWORD \
  --pg-repl-username $PG_REPL_USERNAME --pg-su-password $PG_SU_PASSWORD \
  --store-backend consul \
  --store-endpoints $CONSUL_HTTP_ADDR --listen-address $IP \
  --id $id \
  --port 5431 \
  --pg-listen-address $IP --pg-port 7432 >/proc/1/fd/1 2>/proc/1/fd/2 &
SK_PID=$!

trap "kill $SS_PID ; kill $SP_PID ; kill $SK_PID" 2

wait $SS_PID
wait $SP_PID
wait $SK_PID
