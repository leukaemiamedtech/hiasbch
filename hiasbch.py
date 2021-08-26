#!/usr/bin/env python3
""" HIASBCH Component

Replenishes HIASBCH Smart Contracts and indexes HIASBCH blocks,
addresses, transactions and receipts.

MIT License

Copyright (c) 2021 Asociación de Investigacion en Inteligencia Artificial
Para la Leucemia Peter Moss

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files(the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Contributors:
- Adam Milton-Barker

"""

__version__ = '1.0.0'
__author__ = 'Adam Milton-Barker'

from gevent import monkey
monkey.patch_all()

import bcrypt
import binascii
import json
import os
import psutil
import signal
import requests
import sys
import time
import threading

from datetime import datetime
from flask import Flask, request, Response
from threading import Thread
from requests.auth import HTTPBasicAuth
from web3 import Web3

from modules.helpers import helpers
from modules.hiascdi import hiascdi
from modules.hiashdi import hiashdi
from modules.mqtt import mqtt


class hiasbch():
    """ HIASBCH Component.

    Replenishes HIASBCH Smart Contracts and indexes HIASBCH blocks,
    addresses, transactions and receipts.
    """

    def __init__(self):
        "Initializes the HIASBCH class."

        self.hiasbch = None
        self.hiascdi = None
        self.hiashdi = None
        self.mqtt = None

        self.helpers = helpers("HIASBCH")
        self.confs = self.helpers.confs
        self.credentials = self.helpers.credentials

        self.min_balance = 5000

        self.auth_contract_address = self.credentials["hiasbch"]["contracts"]["hias"]["contract"]
        self.auth_contract_abi = self.credentials["hiasbch"]["contracts"]["hias"]["abi"]

        self.auth_integrity_address = self.credentials["hiasbch"]["contracts"]["iotJumpWay"]["contract"]
        self.auth_integrity_abi = self.credentials["hiasbch"]["contracts"]["iotJumpWay"]["abi"]

        self.helpers.logger.info("Agent initialization complete.")

    def hiascdi_connection(self):
        """Instantiates the HIASCDI Contextual Data Interface connection. """

        self.hiascdi = hiascdi(self.helpers)

        self.helpers.logger.info(
            "HIASCDI Contextual Data Interface connection instantiated.")

    def hiashdi_connection(self):
        """Instantiates the HIASCDI Historical Data Interface connection. """

        self.hiashdi = hiashdi(self.helpers)

        self.helpers.logger.info(
            "HIASHDI Historical Data Interface connection instantiated.")

    def mqtt_connection(self, credentials):
        """Initializes the HIAS MQTT connection. """

        self.mqtt = mqtt(self.helpers, "Agent", credentials)
        self.mqtt.configure()
        self.mqtt.start()

        self.helpers.logger.info(
            "HIAS Integrity MQTT Broker connection created.")

    def hiasbch_connection(self):
        """Initializes the HIASBCH connection. """

        self.start()
        self.w3.geth.personal.unlockAccount(
            self.w3.toChecksumAddress(self.credentials["hiasbch"]["un"]),
                                      self.credentials["hiasbch"]["up"], 0)

        self.helpers.logger.info(
            "HIAS HIASBCH Blockchain connection created.")

    def start(self):
        """ Connects to HIASBCH. """

        self.w3 = Web3(Web3.HTTPProvider(
            "https://" + self.credentials["server"]["host"] \
                + self.credentials["hiasbch"]["endpoint"], request_kwargs={
                    'auth': HTTPBasicAuth(
                        self.credentials["iotJumpWay"]["entity"],
                        self.confs["agent"]["proxy"]["up"])}))

        self.auth_contract = self.w3.eth.contract(
            self.w3.toChecksumAddress(self.auth_contract_address),
            abi=json.dumps(self.auth_contract_abi))

        self.integrity_contract = self.w3.eth.contract(
            self.w3.toChecksumAddress(self.auth_integrity_address),
            abi=json.dumps(self.auth_integrity_abi))

    def get_balance(self, contract):
        """ Gets smart contract balance """

        try:
            balance = contract.functions.getBalance().call(
                {"from": self.w3.toChecksumAddress(self.credentials["hiasbch"]["un"])})
            balance = self.w3.fromWei(balance, "ether")
            return balance
        except:
            e = sys.exc_info()
            self.helpers.logger.error("Get Balance Failed!")
            self.helpers.logger.error(str(e))
            return False

    def replenish(self, contract, to, replenish):
        """ Replenishes the Integrity smart contract """

        try:
            tx_hash = contract.functions.deposit(
                self.w3.toWei(replenish, "ether")).transact({
                    "to": self.w3.toChecksumAddress(to),
                    "from": self.w3.toChecksumAddress(self.credentials["hiasbch"]["un"]),
                    "gas": 1000000,
                    "value": self.w3.toWei(replenish, "ether")})
            txr = self.w3.eth.waitForTransactionReceipt(tx_hash)
            if txr["status"] is 1:
                self.helpers.logger.info("Smart Contract Replenishment Transaction OK! ")
            else:
                self.helpers.logger.info("Smart Contract Replenishment Transaction KO! ")
            return True
        except:
            e = sys.exc_info()
            self.helpers.logger.info("Smart Contract Replenishment KO! ")
            self.helpers.logger.error(str(e))
            return False

    def store_block(self, blockData):
        """ Stores a block in HIASHDI. """

        data_to_json = {
            "Block": blockData["number"],
            "Size": blockData["size"],
            "Timestamp": blockData["timestamp"],
            "Miner": blockData["miner"],
            "GasLimit": blockData["gasLimit"],
            "GasUsed": blockData["gasUsed"],
            "ParentHash": blockData["parentHash"].hex(),
            "Hash": blockData["hash"].hex(),
            "ExtraData": blockData["extraData"].hex(),
            "Difficulty": blockData["difficulty"],
            "TotalDifficulty": blockData["totalDifficulty"],
            "MixHash": blockData["mixHash"].hex(),
            "Uncles": [x.hex() for x in blockData["uncles"]],
            "Sha3Uncles": blockData["sha3Uncles"].hex(),
            "ReceiptsRoot": blockData["receiptsRoot"].hex(),
            "StateRoot": blockData["stateRoot"].hex(),
            "TransactionsRoot": blockData["transactionsRoot"].hex(),
            "LogsBloom": blockData["logsBloom"].hex(),
            "Nonce": blockData["nonce"].hex()}

        self.hiashdi.insert_data("Blocks", data_to_json)

    def process_transactions(self, transactions):
        """ Stores a block in HIASHDI. """

        for tr in transactions:
            transaction = self.w3.eth.getTransaction(tr["hash"].hex())
            self.store_transaction(transaction)
            receipt = self.w3.eth.getTransactionReceipt(tr["hash"].hex())
            self.store_receipt(receipt)

    def store_transaction(self, transaction):
        """ Stores a block in HIASHDI. """

        t_data_to_json = {
            "BlockHash": transaction["blockHash"].hex(),
            "BlockNumber": transaction["blockNumber"],
            "Hash": transaction["hash"].hex(),
            "From": transaction["from"],
            "To": transaction["to"],
            "Value": transaction["value"],
            "Gas": transaction["gas"],
            "GasPrice": transaction["gasPrice"],
            "Nonce": transaction["nonce"],
            "R": transaction["r"].hex(),
            "S": transaction["s"].hex(),
            "V": transaction["v"],
            "Input": transaction["input"],
            "TransactionIndex": transaction["transactionIndex"]}

        self.hiashdi.insert_data("Transactions", t_data_to_json)

    def store_receipt(self, receipt):
        """ Stores a block in HIASHDI. """

        tr_data_to_json = {
            "BlockHash": receipt["blockHash"].hex(),
            "BlockNumber": receipt["blockNumber"],
            "contractAddress": receipt["contractAddress"],
            "From": receipt["from"],
            "To": receipt["to"],
            "Status": receipt["status"],
            "TransactionHash": receipt["transactionHash"].hex(),
            "TransactionIndex": receipt["transactionIndex"],
            "gasUsed": receipt["gasUsed"],
            "cumulativeGasUsed": receipt["cumulativeGasUsed"],
            "logs": receipt["logs"],
            "LogsBloom": receipt["logsBloom"].hex()}

        self.hiashdi.insert_data("Receipts", tr_data_to_json)

    def update_context(self, block):
        """ Stores a block in HIASHDI. """

        self.hiascdi.update_entity(
            self.helpers.credentials["iotJumpWay"]["entity"], "HIASBCH", {
                "lastScannedBlock": {
                    "value": block,
                    "metadata": {"timestamp": {"value": datetime.now().isoformat()}}
                },
                "dateModified": {"value": datetime.now().isoformat()}
        })

    def life(self):
        """ Publishes entity statistics to HIAS. """

        cpu = psutil.cpu_percent()
        mem = psutil.virtual_memory()[2]
        hdd = psutil.disk_usage('/hias').percent
        tmp = psutil.sensors_temperatures()['coretemp'][0].current
        r = requests.get('http://ipinfo.io/json?token=' +
                    self.credentials["iotJumpWay"]["ipinfo"])
        data = r.json()

        if "loc" in data:
            location = data["loc"].split(',')
        else:
            location = ["0.0", "0.0"]

        self.mqtt.publish("Life", {
            "CPU": float(cpu),
            "Memory": float(mem),
            "Diskspace": float(hdd),
            "Temperature": float(tmp),
            "Latitude": float(location[0]),
            "Longitude": float(location[1])
        })

        self.helpers.logger.info("Agent life statistics published.")
        threading.Timer(300.0, self.life).start()

    def threading(self):
        """ Creates required module threads. """

        # Life thread
        threading.Timer(10.0, self.life).start()

    def signal_handler(self, signal, frame):
        self.helpers.logger.info("Disconnecting")
        self.mqtt.disconnect()
        sys.exit(1)

hiasbch = hiasbch()

def main():

    signal.signal(signal.SIGINT, hiasbch.signal_handler)
    signal.signal(signal.SIGTERM, hiasbch.signal_handler)

    hiasbch.hiascdi_connection()
    hiasbch.hiashdi_connection()
    hiasbch.hiasbch_connection()
    hiasbch.mqtt_connection({
        "host": hiasbch.credentials["iotJumpWay"]["host"],
        "port": hiasbch.credentials["iotJumpWay"]["port"],
        "location": hiasbch.credentials["iotJumpWay"]["location"],
        "zone": hiasbch.credentials["iotJumpWay"]["zone"],
        "entity": hiasbch.credentials["iotJumpWay"]["entity"],
        "name": hiasbch.credentials["iotJumpWay"]["name"],
        "un": hiasbch.credentials["iotJumpWay"]["un"],
        "up": hiasbch.credentials["iotJumpWay"]["up"]
    })

    hiasbch.threading()

    # Get the last saved block from HIASCDI
    next_block = int(hiasbch.hiascdi.get_last_block()["lastScannedBlock"]["value"]) + 1

    while True:
        # Get the last  block from HIASBCH
        latest_block = hiasbch.w3.eth.getBlock('latest')['number']
        if next_block < latest_block:

            hiasbch.helpers.logger.info("Processing block " + str(next_block) +
                                        " / " + str(latest_block))
            try:
                # Get the block data
                blockData = hiasbch.w3.eth.getBlock(
                        next_block, full_transactions=True)
                # Store the block data
                hiasbch.store_block(blockData)
                # Process block transacations

                hiasbch.helpers.logger.info("Block transactions: " + str(len(blockData["transactions"])))
                Thread(target=hiasbch.process_transactions,
                    args=(blockData["transactions"], ),
                    daemon=True).start()
                # Update contextual data
                hiasbch.update_context(next_block)
                next_block += 1
            except Exception:
                e = sys.exc_info()
                hiasbch.helpers.logger.error(str(e))
                hiasbch.helpers.logger.info(str(next_block) + " not found!")

        # Check permissions contract balance
        abalance = hiasbch.get_balance(hiasbch.auth_contract)
        hiasbch.helpers.logger.info(
            "Auth Contract has a balance of "  \
            + str(abalance) + " HIAS Ether")

        if abalance < hiasbch.min_balance:
            # Replenish permissions contract balance
            replenishment = hiasbch.min_balance - abalance
            if hiasbch.replenish(
                hiasbch.auth_contract,
                hiasbch.auth_contract_address, replenishment):
                    hiasbch.helpers.logger.info(
                        "Auth Contract balanced replenished to " \
                        + str(hiasbch.min_balance) + " HIAS Ether")

        # Check integrity contract balance
        ibalance = hiasbch.get_balance(hiasbch.integrity_contract)
        hiasbch.helpers.logger.info(
            "Integrity Contract has a balance of " \
            + str(ibalance) + " HIAS Ether")

        if ibalance < hiasbch.min_balance:
            # Replenish integrity contract balance
            replenishment = hiasbch.min_balance - ibalance
            if hiasbch.replenish(
                hiasbch.integrity_contract,
                hiasbch.auth_integrity_address, replenishment):
                    hiasbch.helpers.logger.info(
                        "Integrity Contract balanced replenished to " \
                        + str(hiasbch.min_balance) + " HIAS Ether")

        time.sleep(2)

if __name__ == "__main__":
    main()
