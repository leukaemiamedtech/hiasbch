#!/bin/bash

FMSG="- HIASBCH start up terminated"

sed -i 's/\r//' scripts/install.config
. scripts/install.config

printf -- 'This script will start up HIASBCH on your HIAS Core installation.\n';
read -p "Proceed (y/n)? " proceed
if [ "$proceed" = "Y" -o "$proceed" = "y" ]; then
	geth --mine --http --networkid $hiasbchchain --datadir /hias/hiasbch/data --http.addr $ip --http.corsdomain "*" --miner.etherbase $hiasbchuser --http.api "eth,net,web3,personal" --allow-insecure-unlock --gcmode archive --cache 2048 console
else
	echo $FMSG;
	exit
fi