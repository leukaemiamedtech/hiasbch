pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

contract permissions {

	uint compensation = 1000000000000000000;
	address hiasbch = YourHiasbchAddress;
	bool setup = false;

	struct component {
		address bcaddress;
		string componentType;
		string location;
		string zone;
		string name;
		uint created;
		uint createdBy;
		uint updated;
		bool exists;
	}

	struct agent {
		address bcaddress;
		string location;
		string zone;
		string name;
		uint created;
		uint createdBy;
		uint updated;
		bool exists;
	}

	struct application {
		address bcaddress;
		bool authorized;
		bool admin;
		string location;
		string name;
		uint created;
		uint createdBy;
		uint updated;
		bool exists;
	}

	struct device {
		address bcaddress;
		string location;
		string zone;
		string name;
		uint created;
		uint createdBy;
		uint updated;
		bool exists;
	}

	struct user {
		address bcaddress;
		bool authorized;
		bool admin;
		string name;
		string location;
		uint created;
		uint createdBy;
		uint updated;
		bool exists;
	}

	uint agents = 0;
	uint applications = 0;
	uint components = 0;
	uint devices = 0;
	uint users = 0;

	mapping(string => agent) agentMap;
	mapping(string => application) applicationMap;
	mapping(string => component) componentMap;
	mapping(string => device) deviceMap;
	mapping(string => user) userMap;

	mapping (address => bool) private authorized;
	mapping (address => bool) private admins;

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
			require(msg.value == amount, "Deposit Values Do Not Match");
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

	function callerAuthorized()
		private
		view
		returns(bool) {
			return authorized[msg.sender];
		}

	function addressAuthorized(address _address)
		public
		view
		returns(bool) {
			require(callerAuthorized(), "Access not authorized");
			return authorized[_address];
		}

	function callerAdmin()
		private
		view
		returns(bool) {
			return admins[msg.sender];
		}

	function exists(string memory _type, string memory identifier)
		private
		view
		returns(bool) {
			if(compare(_type, "Agent")){
				return agentMap[identifier].exists;
			} else if(compare(_type, "Application")){
				return applicationMap[identifier].exists;
			} else if(compare(_type, "Device")){
				return deviceMap[identifier].exists;
			} else if(compare(_type, "Component")){
				return componentMap[identifier].exists;
			} else if(compare(_type, "User")){
				return userMap[identifier].exists;
			} else {
				return false;
			}
		}

	function initiate(string memory _identifier, address _address, bool _admin, string memory _name, string memory _location, uint _createdBy, uint _time)
		public {
			require(isHIASBCH(), "Caller Not HIAS");
			require(setup == false, "Setup is not false");
			user memory newUser = user(_address, true, _admin, _name, _location, _time, _createdBy, _time, true);
			userMap[_identifier] = newUser;
			users++;
			if(_admin)
			{
				admins[_address] = true;
			}
			authorized[_address] = true;
			setup = true;
		}

	function registerComponent(string memory _identifier, address _address, string memory _type, string memory _location, string memory _zone, string memory _name, uint _createdBy, uint _time)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			component memory newComponent = component(_address, _type, _location, _zone, _name, _time, _createdBy, _time, true);
			componentMap[_identifier] = newComponent;
			authorized[_address] = true;
			admins[_address] = true;
			components++;
			compensate(payable(msg.sender), compensation);
		}

	function getComponent(string memory _identifier)
		public
		view
		returns(component memory){
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists("Component", _identifier), "Component Does Not Exist");
			return(componentMap[_identifier]);
		}

	function updateComponent(string memory _identifier, string memory _type, string memory _location, string memory _zone, string memory _name, uint _time)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists(_type, _identifier), "Component Does Not Exist");
			component storage currentComponent = componentMap[_identifier];
			currentComponent.location = _location;
			currentComponent.zone = _zone;
			currentComponent.name = _name;
			currentComponent.updated = _time;
			compensate(payable(msg.sender), compensation);
		}

	function registerAgent(string memory _identifier, address _address, string memory _location, string memory _zone, string memory _name, uint _createdBy, uint _time)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			agent memory newAgent = agent(_address, _location, _zone, _name, _time, _createdBy, _time, true);
			agentMap[_identifier] = newAgent;
			agents++;
			compensate(payable(msg.sender), compensation);
		}

	function getAgent(string memory _identifier)
		public
		view
		returns(agent memory){
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists("Agent", _identifier), "Agent Does Not Exist");
			return(agentMap[_identifier]);
		}

	function updateAgent(string memory _identifier, string memory _type, string memory _location, string memory _zone, string memory _name, uint _time)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists(_type, _identifier), "Agent Does Not Exist");
			agent storage currentAgent = agentMap[_identifier];
			currentAgent.location = _location;
			currentAgent.zone = _zone;
			currentAgent.name = _name;
			currentAgent.updated = _time;
			compensate(payable(msg.sender), compensation);
		}

	function registerUser(string memory _identifier, address _address, bool _admin, string memory _name, string memory _location, uint _time, uint _createdBy)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			user memory newUser = user(_address, true, _admin, _name,  _location, _time, _createdBy, _time, true);
			userMap[_identifier] = newUser;
			users++;
			if(_admin)
			{
				admins[_address] = true;
			}
			authorized[_address] = true;
			compensate(payable(msg.sender), compensation);
		}

	function getUser(string memory _identifier)
		public
		view
		returns(user memory){
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists("User", _identifier), "User Does Not Exist");
			return(userMap[_identifier]);
		}

	function updateUser(string memory _identifier, string memory _type, bool _authorized, bool _admin, string memory _name, string memory _location, uint _time)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists(_type, _identifier), "User Does Not Exist");
			user storage currentUser = userMap[_identifier];
			currentUser.authorized = _authorized;
			currentUser.admin = _admin;
			currentUser.name = _name;
			currentUser.location = _location;
			currentUser.updated = _time;
			authorized[currentUser.bcaddress] = currentUser.authorized;
			admins[currentUser.bcaddress] = currentUser.admin;
			compensate(payable(msg.sender), compensation);
		}

	function registerApplication(string memory _identifier, address _address, bool _admin, string memory _location, string memory _name, uint _createdBy, uint _time)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			application memory newApplication = application(_address, true, _admin, _location, _name, _time, _createdBy, _time, true);
			applicationMap[_identifier] = newApplication;
			applications++;
			authorized[_address] = true;
			if(_admin)
			{
				admins[_address] = true;
			}
			compensate(payable(msg.sender), compensation);
		}

	function getApplication(string memory _identifier)
		public
		view
		returns(application memory){
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists("Application", _identifier), "Application Does Not Exist");
			return(applicationMap[_identifier]);
		}

	function updateApplication(string memory _identifier, string memory _type, bool _authorized, bool _admin, string memory _location, string memory _name, uint _time)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists(_type, _identifier), "Application Does Not Exist");
			application storage currentApplication = applicationMap[_identifier];
			currentApplication.authorized = _authorized;
			currentApplication.admin = _admin;
			currentApplication.location = _location;
			currentApplication.name = _name;
			currentApplication.updated = _time;
			authorized[currentApplication.bcaddress] = currentApplication.authorized;
			admins[currentApplication.bcaddress] = currentApplication.admin;
			compensate(payable(msg.sender), compensation);
		}

	function registerDevice(string memory _identifier, address _address, string memory _location, string memory _zone, string memory _name, uint _createdBy, uint _time)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			device memory newDevice = device(_address, _location, _zone, _name, _time, _createdBy, _time, true);
			deviceMap[_identifier] = newDevice;
			devices++;
			compensate(payable(msg.sender), compensation);
		}

	function getDevice(string memory _identifier)
		public
		view
		returns(device memory){
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists("Device", _identifier), "Device Does Not Exist");
			return(deviceMap[_identifier]);
		}

	function updateDevice(string memory _identifier, string memory _type, string memory _location, string memory _zone, string memory _name, uint _time)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			require(exists(_type, _identifier), "Device Does Not Exist");
			device storage currentDevice = deviceMap[_identifier];
			currentDevice.location = _location;
			currentDevice.zone = _zone;
			currentDevice.name = _name;
			currentDevice.updated = _time;
			compensate(payable(msg.sender), compensation);
		}

	function deregsiter(string memory _type, string memory _identifier)
		public {
			require(callerAuthorized(), "Caller Not Authorized");
			if(compare(_type, "Agent")){
				require(exists(_type, _identifier), "Agent Does Not Exist");
				delete authorized[agentMap[_identifier].bcaddress];
				delete agentMap[_identifier];
				agents--;
			} else if(compare(_type, "Application")){
				require(exists(_type, _identifier), "Application Does Not Exist");
				delete authorized[applicationMap[_identifier].bcaddress];
				delete applicationMap[_identifier];
				applications--;
			} else if(compare(_type, "Device")){
				require(exists(_type, _identifier), "Device Does Not Exist");
				delete authorized[deviceMap[_identifier].bcaddress];
				delete deviceMap[_identifier];
				devices--;
			} else if(compare(_type, "Component")){
				require(exists(_type, _identifier), "Component Does Not Exist");
				delete authorized[componentMap[_identifier].bcaddress];
				delete componentMap[_identifier];
				components--;
			} else if(compare(_type, "User")){
				require(exists(_type, _identifier), "User Does Not Exist");
				delete authorized[userMap[_identifier].bcaddress];
				delete userMap[_identifier];
				users--;
			}
			compensate(payable(msg.sender), compensation);
		}

	function count(string memory _type)
		public
		view
		returns (uint data){
			require(callerAuthorized(), "Caller Not Authorized");
			if(compare(_type, "Agent")){
				return agents;
			} else if(compare(_type, "Application")){
				return applications;
			} else if(compare(_type, "Device")){
				return devices;
			} else if(compare(_type, "Components")){
				return components;
			} else if(compare(_type, "User")){
				return users;
			}
		}

	function compare(string memory str1, string memory str2)
		private
		pure
		returns(bool){
			return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
		}

}