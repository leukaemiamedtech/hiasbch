#!/bin/bash

FMSG="HIAS Blockchain component installation terminated!"

sed -i 's/\r//' scripts/install.config
. scripts/install.config

printf -- 'This script will install the HIAS Blockchain component on HIAS Core.\n';
printf -- '\033[33m WARNING: Ensure that your HIAS Conda environment is activated. \033[0m\n';
printf -- '\033[33m WARNING: This is an inteteractive installation, please follow instructions provided. \033[0m\n';

read -p "Proceed (y/n)? " proceed
if [ "$proceed" = "Y" -o "$proceed" = "y" ]; then

        printf -- 'Installing required software.\n';
        conda install -c anaconda bcrypt
        conda install flask
        conda install -c conda-forge paho-mqtt
        conda install psutil
        conda install requests
        conda install -c conda-forge web3
        sudo apt install software-properties-common
        sudo add-apt-repository -y ppa:ethereum/ethereum
        sudo apt update
        sudo apt install ethereum
        sudo apt install composer
        sudo apt install solc
        cd /hias/var/www
        composer require sc0vu/web3.php dev-master
        cd ~/HIAS-Core
        sudo mkdir /hias/hiasbch
        sudo cp -a components/hiasbch/src/* /hias/hiasbch/
        cp components/hiasbch/scripts/Web3PHP/Web3.php /hias/var/www/vendor/sc0vu/web3.php/src
        cp components/hiasbch/scripts/Web3PHP/RequestManager.php /hias/var/www/vendor/sc0vu/web3.php/src/RequestManagers
        cp components/hiasbch/scripts/Web3PHP/HttpRequestManager.php /hias/var/www/vendor/sc0vu/web3.php/src/RequestManagers
        printf -- '\033[32m SUCCESS: Required software installed! \033[0m\n';
        printf -- 'Now you will create primary HIASBCH blockchain account.\n';
        printf -- '\033[33m HINT: Follow the instructions given to create the account. \033[0m\n';
        printf -- '\033[33m WARNING: When asked enter a secure password. \033[0m\n';
        printf -- '\033[33m WARNING: Store the provided address and password in the scripts/install.config file. \033[0m\n';
        read -p "Proceed (y/n)? " proceed
        if [ "$proceed" = "Y" -o "$proceed" = "y" ]; then
            geth account new --datadir /hias/hiasbch/data
        else
            echo $FMSG;
            exit 1
        fi
        printf -- 'Now you will add your HIASBCH account to the HIASBCH Smart Contracts.\n';
        read -p "! Enter your HIASBCH account address: " hiasbchuser
        sudo sed -i -- "s/YourHiasbchAddress/$hiasbchuser/g" /hias/hiasbch/contracts/permissions.sol
        sudo sed -i -- "s/YourHiasbchAddress/$hiasbchuser/g" /hias/hiasbch/contracts/integrity.sol
        printf -- '\033[32m SUCCESS: HIASBCH account added to the HIASBCH Smart Contracts! \033[0m\n';
        printf -- 'Now you will compile the HIASBCH Smart Contracts.\n';
        solc --abi /hias/hiasbch/contracts/permissions.sol -o /hias/hiasbch/contracts/build --overwrite
        solc --bin /hias/hiasbch/contracts/permissions.sol -o /hias/hiasbch/contracts/build --overwrite
        solc --abi /hias/hiasbch/contracts/integrity.sol -o /hias/hiasbch/contracts/build --overwrite
        solc --bin /hias/hiasbch/contracts/integrity.sol -o /hias/hiasbch/contracts/build --overwrite
        printf -- '\033[32m SUCCESS: HIASBCH Smart Contracts compiled! \033[0m\n';
        printf -- 'Now you will update the HIASBCH Genesis file.\n';
        sudo sed -i -- "s/YourHiasbchChainId/$hiasbchchain/g" /hias/hiasbch/genesis.json
        sudo sed -i -- "s/YourHiasbchAddress/$hiasbchuser/g" /hias/hiasbch/genesis.json
        printf -- '\033[32m SUCCESS: HIASBCH Genesis file updated! \033[0m\n';
        printf -- 'Now you will start HIASBCH.\n';
        geth --datadir /hias/hiasbch/data init /hias/hiasbch/genesis.json
        printf -- '\033[33m HINT: Before you continue have the HIASBCH installation guide open at the "Deploy HIASBCH Smart Contracts With Geth" section. \033[0m\n';
        printf -- '\033[33m HINT: Once HIASBCH has started follow the guide to deploy the HIASBCH Smart Contracts. \033[0m\n';
        printf -- '\033[33m WARNING: It is very important you save the details provided during this step as explained in the guide! \033[0m\n';
        read -p "Are you ready (y/n)? " readyforit
        if [ "$readyforit" = "Y" -o "$readyforit" = "y" ]; then
            geth --mine --http --networkid $hiasbchchain --datadir /hias/hiasbch/data --http.addr $ip --http.corsdomain "*" --miner.etherbase $hiasbchuser --http.api "eth,net,web3,personal" --allow-insecure-unlock --cache 2048 --gcmode archive console
            printf -- '\033[32m SUCCESS: You should now have all of the details required to complete the HIASBCH installation later in the finalizing stage! \033[0m\n';
            printf -- '\033[33m HINT: Before you continue with the installation, complete the final steps in the HIASBCH guide and start mining on HIASBCH. \033[0m\n';
        else
            echo $FMSG;
            exit
        fi

        printf -- '\033[32m SUCCESS: HIASBCH installed! \033[0m\n';

else
    echo $FMSG;
    exit
fi