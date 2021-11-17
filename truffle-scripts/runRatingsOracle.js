// eslint-disable-next-line func-names
module.exports = function (callback) {
  const jobId = `0x${process.argv[2].replaceAll('-', '')}`

  if (!jobId || jobId.length === 0) callback(new Error('JobId missing'))
  // eslint-disable-next-line no-undef
  TestCLFlightRatingsOracle.deployed()
    .then((TestRating) => {
      TestRating.request2(jobId)
      // eslint-disable-next-line no-console
        .then((tx) => console.log(tx))
    })

  callback()
}
