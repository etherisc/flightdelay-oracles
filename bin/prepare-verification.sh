#!/usr/bin/env bash

mkdir -p ./verification

function flatten {
  ./node_modules/.bin/truffle-flattener $1 | sed "s|$PWD|.|g" > $2
   echo "Source code prepared for" $1
}

# Services
# flatten ./contracts/services/InstanceOperatorService.sol ./verification/InstanceOperatorService.txt
flatten ./contracts/Oracles/CLFlightRatingsOracle.sol ./verification/CLFlightRatingsOracle.txt
flatten ./contracts/Oracles/CLFlightStatusesOracle.sol ./verification/CLFlightStatuses.txt
