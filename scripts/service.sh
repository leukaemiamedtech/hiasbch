#!/bin/bash

FMSG="HIASBCH service installation terminated!"

printf -- 'This script will install the HIASBCH service on HIAS Core.\n';

read -p "Proceed (y/n)? " proceed
if [ "$proceed" = "Y" -o "$proceed" = "y" ]; then

        printf -- 'Installing HIASBCH service.\n';
        sudo touch /lib/systemd/system/HIASBCH.service
        echo "[Unit]" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "Description=HIASBCH service" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "After=multi-user.target" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "After=HIASCDI.service" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "[Service]" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "User=$USER" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "Type=simple" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "Restart=on-failure" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "ExecStart=/home/$USER/HIAS-Core/components/hiasbch/scripts/component.sh" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "[Install]" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "WantedBy=multi-user.target" | sudo tee -a /lib/systemd/system/HIASBCH.service
        echo "" | sudo tee -a /lib/systemd/system/HIASBCH.service

        sudo sed -i -- "s/YourUser/$USER/g" /home/$USER/HIAS-Core/components/hiasbch/scripts/component.sh

        sudo systemctl enable HIASBCH.service

        printf -- '\033[32m SUCCESS: HIASBCH service installed! \033[0m\n';

else
    echo $FMSG;
    exit
fi