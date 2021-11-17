const fs = require('fs-jetpack')

const main = () => {
  const templateName = process.argv[2]
  const dotName = process.argv[3]
  const tomlName = process.argv[4]

  const template = fs.read(templateName)
  const dot = fs.read(dotName)
  const toml = template
    .replace(
      '"""\n"""',
      dot
        .replace('digraph {', '"""')
        .replace('} //digraph', '"""')
        .replaceAll('\\', '\\\\'),
    )
  fs.write(tomlName, toml)
}

main()
