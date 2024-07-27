// SPDX-License-Identifier:MIT
pragma solidity ^0.8.23;

import {InsuranceVaultEngine} from "./InsuranceVaultEngine.sol";
import {FunctionsClient} from "@chainlink/contracts/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/automation/AutomationCompatible.sol";

/**
 * @title Operations.sol
 * @author Aaryan Urunkar
 * @notice To handle operations for the insurance system such as automating claims, calculating weather of each user
 */
contract Operations is FunctionsClient, InsuranceVaultEngine, AutomationCompatibleInterface, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    address public constant ROUTER_ADDRESS = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0; //Hardcoded for sepolia
    uint32 public constant GAS_LIMIT = 300000;
    bytes32 public constant DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000; //Hardcoded for sepolia
    uint64 public constant SUB_ID = 3291;
    uint256 public constant ONE_HOUR = 60 * 60;
    // bytes public constant ENCRYPTED_SECRETS_URL = 0xa266736c6f744964006776657273696f6e1a66a531a2;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    uint256 s_lastAutomationTimestamp;

    /**
     * @dev This is the API call source code written in javascript
     *
     */
    string constant SOURCE = "const latitude = args[0];" "const longitude = args[1];"
        "const apiKey = secrets.apiKey; // Your OpenWeather API key" "if (!apiKey) {"
        "throw Error(`OPENWEATHER_ API_KEY environment variable not set for OpenWeather API. Get a free key from https://openweathermap.org/api`);"
        "}" "// build HTTP request object" "const openWeatherRequest = Functions.makeHttpRequest({"
        "url: `https://api.openweathermap.org/data/2.5/weather`," "headers: {" "    `Content-Type`: `application/json`,"
        "}," "params: {" "    lat: latitude," "    lon: longitude," "    appid: apiKey,"
        "    units: 'metric', // Optional: units can be 'metric', 'imperial', or 'standard'" "}," "});"
        "// Make the HTTP request" "const openWeatherResponse = await openWeatherRequest;"
        "if (openWeatherResponse.error) {" "throw new Error(`OpenWeather Error`);" "}" "// fetch the temperature"
        "const temperature = openWeatherResponse.data.main.temp;" "console.log(openWeatherResponse?.data.clouds.all);"
        "const point1 = openWeatherResponse?.data.weather[0].id == 202 ? 1:0;"
        "const point2 = openWeatherResponse?.data.weather[0].id == 781 ? 1:0;"
        "const point3 = openWeatherResponse?.data.weather[0].id == 504 ? 1:0;"
        "const point4 = openWeatherResponse?.data.weather[0].id == 622 ? 1:0;"
        "const point5 = openWeatherResponse?.data.wind.speed > 150 ? 1:0;"
        "const point6 = (openWeatherResponse?.data.rain && openWeatherResponse?.data.rain >= 8)? 1:0; "
        "const point7 = openWeatherResponse?.data.clouds.all >= 95? 1:0;"
        "const aggregate = point1 + point2 + point3 + point4 + point5 + point6 + point7;"
        "return Functions.encodeString(aggregate + " ");";

    /**
     * Constructor for the Operations.sol contract
     */
    constructor(address _vault, address _asset)
        FunctionsClient(ROUTER_ADDRESS)
        InsuranceVaultEngine(_vault, _asset)
        ConfirmedOwner(msg.sender)
    {
        s_lastAutomationTimestamp = block.timestamp;
    }

    /**
     * @notice  A function to send API request to fetch API data which will be cleared in fulfillRequests()
     * @dev     DON Hosted secrets details:
     *          Uploaded secrets details(latest):
     *          Version: 1722077996
     *          slot: 0
     *          To gateways: https://01.functions-gateway.testnet.chain.link/,https://02.functions-gateway.testnet.chain.link/
     *
     *  @param user The address of the user
     *  @param donHostedSecretsSlotID The slot ID where the secrets are hosted on the DON
     *  @param donHostedSecretsVersion The version of the secrets when they are uploaded to the DON
     *  @return  requestId  The request ID designated for the particular API call
     */
    function sendRequest(address user, uint8 donHostedSecretsSlotID, uint64 donHostedSecretsVersion)
        internal
        returns (bytes32)
    {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(SOURCE);
        req.addDONHostedSecrets(donHostedSecretsSlotID, donHostedSecretsVersion);

        string[] memory args = new string[](2);
        args[0] = Strings.toString(getUserLatitude(user));
        args[1] = Strings.toString(getUserLongitude(user));

        s_lastRequestId = _sendRequest(req.encodeCBOR(), SUB_ID, GAS_LIMIT, DON_ID);
        return s_lastRequestId;
    }

    /**
     * @notice  A function to recieve data from API
     * @dev Inherited from FunctionsClient.sol
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual override {
        //If the uint256(response) is greater than or equal to 4 we have to initiate a withdrawal process to that user
    }

    /**
     * @notice  A function to check if an hour has passed before checking all the users' eligibility for a claim
     * @dev     Inherited from AutomationCompatibleInterface.sol
     * @return  upkeepNeeded  A bool to check if the automated tasks should run or not. If true, they should, else, they shouldnt
     * @return  bytes  .
     * 
     * Basically if one hour has passed since the last time this function has run, and if there are users in the protocol, this
     * function will return true
     */
    function checkUpkeep(bytes calldata /* checkData */ )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool ifUsers = getUsers().length > 0;
        bool ifTimeHasPassed = (s_lastAutomationTimestamp + ONE_HOUR) < block.timestamp;
        upkeepNeeded = ifUsers && ifTimeHasPassed;
        return (upkeepNeeded , "0x0");
    }

    /**
     * @notice A function which runs every hour and checks if there are any users eligible for claims or not
     * @dev Inherited from AutomationCompatibleInterface.sol
     * 
     */
    function performUpkeep(bytes calldata /* performData */ ) external override {}
}
