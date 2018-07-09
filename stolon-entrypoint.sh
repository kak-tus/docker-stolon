#!/usr/bin/env sh

if [ "$SET_CONTAINER_TIMEZONE" = "true" ]; then
  echo "$CONTAINER_TIMEZONE" >/etc/timezone \
  && ln -sf /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata
  echo "Container timezone set to: $CONTAINER_TIMEZONE"
else
  echo "Container timezone not modified"
fi

id=$( echo $EXT_HOSTNAME | awk -F '.' '{ print $1 }' | sed 's/[^a-z0-9\_]/_/g' )
echo $id

mkdir -p /var/lib/postgresql/data
chown postgres:postgres /var/lib/postgresql/data

if [ "$STOLON_SERVICE" = "sentinel" ]; then
  gosu postgres /usr/local/bin/stolon-sentinel \
    --cluster-name $STOLON_CLUSTER_NAME \
    --store-backend etcdv3 \
    --store-endpoints $ETCD_HTTP_ADDR &
  child=$!
elif [ "$STOLON_SERVICE" = "proxy" ]; then
  gosu postgres /usr/local/bin/stolon-proxy \
    --cluster-name $STOLON_CLUSTER_NAME \
    --store-backend etcdv3 \
    --store-endpoints $ETCD_HTTP_ADDR \
    --listen-address 0.0.0.0 \
    --port 5432 &
  child=$!
elif [ "$STOLON_SERVICE" = "keeper" ]; then
  gosu postgres /usr/local/bin/stolon-keeper  \
    --cluster-name $STOLON_CLUSTER_NAME \
    --store-backend etcdv3 \
    --store-endpoints $ETCD_HTTP_ADDR \
    --data-dir /var/lib/postgresql/data \
    --pg-bin-path /usr/lib/postgresql/10/bin/ \
    --pg-repl-password $PG_REPL_PASSWORD \
    --pg-repl-username $PG_REPL_USERNAME \
    --pg-su-password $PG_SU_PASSWORD \
    --uid $id \
    --pg-listen-address $STOLON_IP \
    --pg-port 7432 &
    child=$!
fi

trap "kill $child" INT TERM
wait "$child"
trap - INT TERM
wait "$child"
