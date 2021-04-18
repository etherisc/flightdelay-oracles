const Gifcli = require('@etherisc/gifcli');

module.exports = async () => {

  const gif = await Gifcli.connect();

  const productServiceDeployed = await gif.artifact.get('platform', 'development', 'ProductService');
  console.log(productServiceDeployed);

  const instanceOperatorServiceDeployed = await gif.artifact.get('platform', 'development', 'InstanceOperatorService');
  console.log(instanceOperatorServiceDeployed);

}
