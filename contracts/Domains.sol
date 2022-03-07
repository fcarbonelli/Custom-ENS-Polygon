// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {StringUtils} from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";
import "hardhat/console.sol";

error Unauthorized();
error AlreadyRegistered();
error InvalidName(string name);

contract Domains is ERC721URIStorage {
    // Magic given to us by OpenZeppelin to help us keep track of tokenIds.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;

    address payable public owner;

    // We'll be storing our NFT images on chain as SVGs
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><svg xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.com/svgjs" width="270" height="270" preserveAspectRatio="none" viewBox="0 0 270 270"><g mask="url(&quot;#SvgjsMask2965&quot;)" fill="none"><rect width="270" height="270" x="0" y="0" fill="url(#SvgjsLinearGradient2966)"></rect><path d="M248.591,46.603C257.531,45.976,262.102,36.791,266.375,28.913C270.363,21.561,274.264,13.45,270.667,5.899C266.624,-2.588,257.989,-8.182,248.591,-8.417C238.79,-8.662,229.336,-3.792,224.512,4.743C219.758,13.154,221.069,23.378,225.887,31.753C230.72,40.154,238.923,47.281,248.591,46.603" fill="rgba(190, 190, 190, 0.4)" class="triangle-float2"></path><path d="M236.7060730548998 298.9670165800403L276.4428759204906 261.91184843299857 239.38770777344888 222.17504556740772 199.65090490785803 259.23021371444946z" fill="rgba(190, 190, 190, 0.4)" class="triangle-float2"></path><path d="M102.04380933125107 197.26519339874565L77.3330704045726 238.3907691881369 143.1693851206423 221.9759323254241z" fill="rgba(190, 190, 190, 0.4)" class="triangle-float3"></path><path d="M235.61423375749655 147.0920712483751L216.612751267568 57.27631659190894 156.04662470976635 109.92564716950505z" fill="rgba(190, 190, 190, 0.4)" class="triangle-float3"></path><path d="M279.3293353261618 71.2737630845936L204.77071375037175 125.3352837351761 277.7341207655391 159.3586791914288z" fill="rgba(190, 190, 190, 0.4)" class="triangle-float3"></path><path d="M105.573,173.693C125.733,173.413,143.388,160.841,153.011,143.124C162.2,126.206,160.664,106.154,151.431,89.26C141.758,71.561,125.743,56.377,105.573,56.328C85.337,56.279,69.279,71.416,59.329,89.037C49.571,106.317,46.286,127.056,55.8,144.472C65.685,162.568,84.955,173.979,105.573,173.693" fill="rgba(190, 190, 190, 0.4)" class="triangle-float2"></path><path d="M191.5,143.697C216.183,142.228,236.606,127.455,249.955,106.641C264.73,83.603,277.203,55.014,263.609,31.26C249.96,7.41,218.979,4.521,191.5,4.5C163.972,4.479,134.272,8.114,119.203,31.151C102.922,56.04,103.54,89.373,119.614,114.396C134.604,137.73,163.815,145.344,191.5,143.697" fill="rgba(190, 190, 190, 0.4)" class="triangle-float2"></path></g><defs><mask id="SvgjsMask2965"><rect width="270" height="270" fill="#ffffff"></rect></mask><linearGradient x1="0%" y1="0%" x2="100%" y2="100%" gradientUnits="userSpaceOnUse" id="SvgjsLinearGradient2966"><stop stop-color="rgba(44, 134, 223, 1)" offset="0"></stop><stop stop-color="rgba(90, 37, 172, 1)" offset="0.7"></stop><stop stop-color="rgba(227, 25, 195, 1)" offset="1"></stop></linearGradient><style>@keyframes float1 {0%{transform: translate(0, 0)}50%{transform: translate(-10px, 0)}100%{transform: translate(0, 0)}}.triangle-float1 {animation: float1 5s infinite;}@keyframes float2 {0%{transform: translate(0, 0)}50%{transform: translate(-5px, -5px)}100%{transform: translate(0, 0)}}.triangle-float2 {animation: float2 4s infinite;}@keyframes float3 {0%{transform: translate(0, 0)}50%{transform: translate(0, -10px)}100%{transform: translate(0, 0)}}.triangle-float3 {animation: float3 6s infinite;}</style></defs></svg><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".5" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="#fff"/><text x="32.5" y="230" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = "</text></svg>";

    // A "mapping" data type to store their names
    mapping(string => address) public domains;

    mapping(string => string) public records;

    mapping(uint256 => string) public names;

    constructor(string memory _tld)
        payable
        ERC721("Spark Name Service", "SNS")
    {
        owner = payable(msg.sender);
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    // A register function that adds their names to our mapping
    function register(string calldata name) public payable {
        if (domains[name] != address(0)) revert AlreadyRegistered();
        if (!valid(name)) revert InvalidName(name);

        uint256 _price = price(name);
        require(msg.value >= _price, "Not enough Matic paid");

        // Combine the name passed into the function  with the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));
        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log(
            "Registering %s.%s on the contract with tokenID %d",
            name,
            tld,
            newRecordId
        );

        // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _name,
                        '", "description": "A domain on the Spark name service", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '","length":"',
                        strLen,
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        console.log(
            "\n--------------------------------------------------------"
        );
        console.log("Final tokenURI", finalTokenUri);
        console.log(
            "--------------------------------------------------------\n"
        );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;

        names[newRecordId] = name;
        _tokenIds.increment();
    }

    // This will give us the domain owners' address
    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        // Check that the owner is the transaction sender
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name)
        public
        view
        returns (string memory)
    {
        return records[name];
    }

    // This function will give us the price of a domain based on length
    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 5 * 10**17; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
            return 3 * 10**17; // To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
            return 1 * 10**17;
        }
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Matic");
    }

    function getAllNames() public view returns (string[] memory) {
        console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    function valid(string calldata name) public pure returns (bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
    }
}
