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

    address public constant router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0; //Hardcoded for sepolia
    uint32 public constant gasLimit = 300000;
    bytes32 public constant donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000; //Hardcoded for sepolia

    string source = "const latitude = args[0];"
                    "const longitude = args[1];"
                    "const apiKey = secrets.apiKey; // Your OpenWeather API key"
                    "if (!apiKey) {"
                    "throw Error(`OPENWEATHER_ API_KEY environment variable not set for OpenWeather API. Get a free key from https://openweathermap.org/api`);"
                    "}"
                    "// build HTTP request object"
                    "const openWeatherRequest = Functions.makeHttpRequest({"
                    "url: `https://api.openweathermap.org/data/2.5/weather`,"
                    "headers: {"
                    "    `Content-Type`: `application/json`,"
                    "},"
                    "params: {"
                    "    lat: latitude,"
                    "    lon: longitude,"
                    "    appid: apiKey,"
                    "    units: 'metric', // Optional: units can be 'metric', 'imperial', or 'standard'"
                    "},"
                    "});"
                    "// Make the HTTP request"
                    "const openWeatherResponse = await openWeatherRequest;"
                    "if (openWeatherResponse.error) {"
                    "throw new Error(`OpenWeather Error`);"
                    "}"
                    "// fetch the temperature"
                    "const temperature = openWeatherResponse.data.main.temp;"
                    "console.log(openWeatherResponse?.data.clouds.all);"
                    "const point1 = openWeatherResponse?.data.weather[0].id == 202 ? 1:0;"
                    "const point2 = openWeatherResponse?.data.weather[0].id == 781 ? 1:0;"
                    "const point3 = openWeatherResponse?.data.weather[0].id == 504 ? 1:0;"
                    "const point4 = openWeatherResponse?.data.weather[0].id == 622 ? 1:0;"
                    "const point5 = openWeatherResponse?.data.wind.speed > 150 ? 1:0;"
                    "const point6 = (openWeatherResponse?.data.rain && openWeatherResponse?.data.rain >= 8)? 1:0; "
                    "const point7 = openWeatherResponse?.data.clouds.all >= 95? 1:0;"
                    "const aggregate = point1 + point2 + point3 + point4 + point5 + point6 + point7;"
                    "return Functions.encodeUint256(aggregate);";

    constructor() FunctionsClient(router) {}

    /**
     * @notice  A function to recieve data from API
     * @dev Inherited from FunctionsClient.sol
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual override {}
}
