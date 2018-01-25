if [ -f server_list.cfg ]; then
   . $(dirname $(dirname $(readlink -f $0)))/etc/xcat.sh
   node_list=()
   while read x ; do
       id=$(echo $x | awk -F, '{print $2}');
       [ -n "$id" ] && node_list[$id]=$(echo $x | awk -F, '{print $1}');
   done < <(echo $(lsdef -t node -o all -i id) | sed "s/id=/,/g" | sed "s/Object name: /\n/g" | sed "s/ ,/,/g")
   
   for ii in $(cat server_list.cfg); do
      node_id=$(echo $ii | awk -F\| '{print $1}')
      node_name=${node_list[$node_id]}
      node_update=""
      node_mac=$(echo $ii | awk -F\| '{print $2}')
      [ -n "$node_mac" ] && node_update="mac=$node_mac"
      node_bmc_ip=$(echo $ii | awk -F\| '{print $3}')
      [ -n "$node_bmc_ip" ] && node_update="$node_update bmc=$node_bmc_ip"
      [ -n "$node_update" ] && chdef -t node $node_name $node_update
   done
else
   echo "server_list.cfg file not found"
fi
