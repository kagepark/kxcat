if [ -f server_list.cfg ]; then
   for ii in $(cat server_list.cfg); do
      srv_id=$(echo $ii | awk -F\| '{print $1}')
      srv_info=$(echo $ii | awk -F\| '{print $2}')
      srv_name=node-$(printf "%05d" $srv_id)
      chdef -t node $srv_name mac=$srv_mac
   done
else
   echo "server_list.cfg file not found"
fi
