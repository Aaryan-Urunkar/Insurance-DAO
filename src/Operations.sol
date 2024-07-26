// SPDX-License-Identifier:MIT
pragma solidity ^0.8.23;

import {InsuranceVaultEngine} from "./InsuranceVaultEngine.sol";
import {FunctionsClient} from "@chainlink/contracts/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

/**
 * @title Operations.sol
 * @author Aaryan Urunkar
 * @notice To handle operations for the insurance system such as automating claims, calculating weather of each user
 */
contract Operations is FunctionsClient {
    address public constant ROUTER_ADDRESS = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0; //Hardcoded for sepolia
    uint32 public constant GAS_LIMIT = 300000;
    bytes32 public constant DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000; //Hardcoded for sepolia

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
        "return Functions.encodeUint256(aggregate);";

    /**
     * Constructor for the Operations.sol contract
     */
    constructor() FunctionsClient(ROUTER_ADDRESS) {}



    
    /**
     * @notice  A function to send API request to fetch API data which will be cleared in fulfillRequests()
     * @dev     The encrypted secrets URL is:
     *          0xd796f01a879a29cfb7d83d92de0a483d03fa4f52a2ce2cabc66bc58751ab188da115184e6bee5a1853c25b2a7d4e58d25ed98806442d269e51ad8b6c91fc571c5224b761f404b0be4585bc7c591e4f06ae11c8e03f69d6186de0f27ad8695da66b43ea3227e9c94e6afaf48941d7ac589ad0c76eb94043f2a5bc5ac54b2c9a5ca38984feda967aab69b5a2c78cdb453d19e920dc44683e92d5d204632266a91554a4d6f27852a9f13515311ca63213fd82
     * @param   encryptedSecretsUrls  The encrypted secrets URL where API keys and other secrets are stored off chain
     * @param   args  The args for the javascript API call source code
     * @param   subscriptionId  The subscription ID created at functions.chain.link
     * @return  requestId  The request ID designated for the particular API call
     */
    function sendRequest(
        bytes memory encryptedSecretsUrls,
        string[] memory args,
        uint64 subscriptionId
    ) internal returns (bytes32 requestId) {

    }

    /**
     * @notice  A function to recieve data from API
     * @dev Inherited from FunctionsClient.sol
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual override {
        //If the uint256(response) is greater than or equal to 4 we have to initial a withdrawal process to that user
    }
}
