// SPDX-License-Identifier: LZBL-1.2
pragma solidity ^0.8.0;

import { AddressCast } from "@layerzerolabs/lz-evm-protocol-v2/contracts/libs/AddressCast.sol";

import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import { IOFT, SendParam, OFTReceipt, MessagingReceipt, MessagingFee } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

import { Script, console } from "forge-std/Script.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
import { MyAssetOFT } from "../contracts/MyAssetOFT.sol";

// forge script script/SendScript.s.sol   --rpc-url https://base-sepolia.drpc.org   --private-key eec5114d22861479be10c9db7850f75473bbcde37076163fbf94222a3864ee74   --sig "exec(address,string,uint256,uint256,uint128,uint128)"   0x815187F4CddE962a5afE5057b360E8fCa5bc4aa1   "arb-sep"   1ether   0   50000   0   --broadcast

/**
 * @title Lets the user send an LZ OFT transfer to transfer an amount of OFT from a source EVM chain to OVault testnet or mainnet
 * @notice There are 3 supported modes that correspond to <amount>, <gas>, <value> in the forge script below:
 * @notice forge script script/SendScript.s.sol --private-key $PRIVATE_KEY --rpc-url $RPC_URL_BASE_TESTNET
  --sig "exec(address,string,uint256,uint256,uint128,uint128)" $SHARE_OFT_BASE_SEP  "base-sep" 1ether 0 50000 [--broadcast]
0  0.000025ether --broadcast
 * @notice 1. Send to HyperEVM 
                - true, false, false
 * @notice 2. Send to HyperCore 
                - true, true, false
 * @notice 3. Send to HyperCore + Fund HyperCore with HYPE 
                - true, true, true
 */


/*
forge script script/SendScript.s.sol --rpc-url https://base-sepolia.drpc.org --private-key eec5114d22861479be10c9db7850f75473bbcde37076163fbf94222a3864ee74 --sig "exec(address,string,uint256,uint256,uint128,uint128)" 0xED4e1aCFbD615C834cC1Ea60E95D7dDd297422f9 "arb-sep" 1ether 0 0 0 0.000025ether --broadcast
*/

 /*
 npx hardhat etherscan-verify --api-key UITCH99PJ8WH1T5K1Y3ZWQH9PZZ88M4R9P --api-url https://api.arbiscan.io --contract-name MyOFT --network arbitrum
  */
contract SendScript is Script {
    using AddressCast for address;
    using OptionsBuilder for bytes;

    address payable public address_composer;

    OFT public myOFT_SRC;
    address public address_src_OFT;

    mapping(uint256 => uint32) public chainIdToSrcEid;
    mapping(string => uint32) public chainNameToDstEid;

    uint32 public HUB_EID = 40231;

    function setUp() public {
        chainIdToSrcEid[421614] = 40231; // arb sep
        chainIdToSrcEid[11155420] = 40232; // opt sep
        chainIdToSrcEid[84532] = 40245; // base sep

        chainNameToDstEid["arb-sep"] = 40231; // arb sep
        chainNameToDstEid["opt-sep"] = 40232; // opt sep
        chainNameToDstEid["base-sep"] = 40245; // base sep
        chainNameToDstEid["bad-eid"] = 100000; // bad eid

        address_composer = payable(0xC629C57CFC8371819AB16963960E8c6FD497bb53);
        // address_composer = payable(0x9e5Db021D525BC465343Bcfe4e17BF36Ea96Ace7);
    }

   function exec(
        address _fromOFT,
        string memory _dstChain,
        uint256 _amount,
        uint256 _minAmount,
        uint128 _lzComposeGas,
        uint128 _lzComposeValue
    ) public {
        uint32 srcEid = chainIdToSrcEid[block.chainid];
        if (srcEid == 0) {
            revert("Source chain is not Arbitrum Sepolia, Optimism Sepolia, or Base Sepolia");
        }

        uint32 dstEid = chainNameToDstEid[_dstChain];
        if (dstEid == 0) {
            revert("Destination chain is not Arbitrum Sepolia, Optimism Sepolia, or Base Sepolia");
        }

        myOFT_SRC = OFT(_fromOFT);

        SendParam memory sendParam = buildSendParam(
            address_composer,
            msg.sender,
            _amount,
            _minAmount,
            dstEid,
            _lzComposeGas,
            _lzComposeValue
        );

        vm.startBroadcast();

        // Mint tokens to msg.sender before sending
        MyAssetOFT(_fromOFT).mint(msg.sender, _amount);

        MessagingFee memory msgFee = quoteSend(sendParam);
        require(msgFee.nativeFee <= 0.0002 ether, "Fee exceeds 0.0002 ether cap");

        _send(sendParam, msgFee);

        vm.stopBroadcast();
    }

    function buildSendParam(
        address _composer,
        address _receiver,
        uint256 _tokenAmount,
        uint256 _minAmount,
        uint32 _dstEid,
        uint128 _lzComposeGas,
        uint128 _lzComposeValue
    ) public view returns (SendParam memory sendParam) {
        bytes memory options;
        bytes memory composeMsg = "";
        uint32 dstEid = _dstEid;
        bytes32 to = addressToBytes32(_receiver);

        if (_lzComposeGas > 0) {
            options = OptionsBuilder.newOptions().addExecutorLzComposeOption(0, _lzComposeGas, _lzComposeValue);
            SendParam memory hopSendParam = SendParam({
                dstEid: dstEid,
                to: to,
                amountLD: _tokenAmount,
                minAmountLD: _minAmount,
                extraOptions: hex"",
                composeMsg: composeMsg,
                oftCmd: hex""
            });
            composeMsg = abi.encode(hopSendParam);
            to = addressToBytes32(_composer);
            dstEid = HUB_EID;
        }

        sendParam = SendParam({
            dstEid: dstEid,
            to: to,
            amountLD: _tokenAmount,
            minAmountLD: _tokenAmount,
            extraOptions: options,
            composeMsg: composeMsg,
            oftCmd: ""
        });
    }

    function quoteSend(SendParam memory _sendParam) public view returns (MessagingFee memory) {
        return myOFT_SRC.quoteSend(_sendParam, false);
    }

    function _send(SendParam memory _sendParam, MessagingFee memory _fee) internal {
        myOFT_SRC.send{ value: _fee.nativeFee }(_sendParam, _fee, msg.sender);
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
