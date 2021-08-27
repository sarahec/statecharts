#! /bin/bash
dart run test --coverage .tempCoverageDir
dart run coverage:format_coverage -l -c --report-on lib -i .tempCoverageDir --packages .packages -o ../coverage/lcov.info
rm -rf .tempCoverageDir
