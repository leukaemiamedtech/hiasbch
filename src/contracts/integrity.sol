pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

contract integrity {

	uint compensation = 1000000000000000000;
	address hiasbch = YourHiasbchAddress;
	bool setup = false;

	struct dataHash {
		bytes dataHash;
		uint created;
		uint createdBy;
		string publishedBy;
		bool exists;
	}

	uint hashes = 0;

	mapping (string => dataHash) hashMap;
	mapping (address => bool) private authorized;

	function isHIASBCH()
		private
		view
		returns(bool) {
			return msg.sender == hiasbch;
		}

	function getBalance()
		public
		view
		returns (uint256) {
			require(isHIASBCH(), "Caller Not HIAS");
			return address(this).balance;
		}

	function deposit(uint256 amount)
		payable
		public {
			require(isHIASBCH(), "Caller Not HIAS");
			require(msg.value == amount);
		}

	function updateCompensation(uint amount)
		public {
			require(isHIASBCH(), "Caller Not HIAS");
			compensation = amount;
		}

	function compensate(address payable _address, uint256 amount)
		private {
			require(amount <= address(this).balance,"Not enough balance");
			_address.transfer(amount);
		}

	function accessAllowed(address _address)
		public
		view
		returns(bool) {
			return authorized[_address];
		}

	function hashExists(string memory _identifier)
		public
		view
		returns(bool) {
			require(accessAllowed(msg.sender), "Access not allowed");
			return hashMap[_identifier].exists == true;
		}

	function initiate(address _address)
		public {
			require(isHIASBCH(), "Caller Not HIAS");
			require(setup == false, "Setup is not false");
			authorized[_address] = true;
			setup = true;
		}

	function registerAuthorized(address _address)
		public {
			require(accessAllowed(msg.sender), "Access not allowed");
			authorized[_address] = true;
			compensate(payable(msg.sender), compensation);
		}

	function deregisterAuthorized(address _address)
		public {
			require(accessAllowed(msg.sender), "Access not allowed");
			delete authorized[_address];
			compensate(payable(msg.sender), compensation);
		}

	function registerHash(string memory dataId, bytes memory _dataHash, uint _time, uint _createdBy, string memory _identifier, address payable _address)
		public {
			require(accessAllowed(msg.sender), "Access not allowed");
			dataHash memory newHashMap = dataHash(_dataHash, _time, _createdBy, _identifier, true);
			hashMap[dataId] = newHashMap;
			hashes++;
			compensate(payable(msg.sender), compensation);
			compensate(_address, compensation);
		}

	function getHash(string memory _identifier)
		public
		view
		returns(dataHash memory){
			require(accessAllowed(msg.sender), "Access not allowed");
			require(hashExists(_identifier), "Hash does not exist");
			return(hashMap[_identifier]);
		}

	function count()
		public
		view
		returns (uint){
			require(accessAllowed(msg.sender), "Access not allowed");
			return hashes;
		}

}