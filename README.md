# Acuparse Automated Installation Script

See the [Acuparse Install Guide](https://docs.acuparse.com/INSTALL) for further install details.

> **WARNING:** ONLY Supports Debian/Rasbian Buster(10) and Ubuntu Bionic(18.04).

## Usage

Install your base Debian/Ubuntu based operating system. Then, run this installer:

`curl -O https://gitlab.com/acuparse/installer/raw/master/install && sudo bash install | tee ~/acuparse.log`

If that fails, try:

`wget https://gitlab.com/acuparse/installer/raw/master/install && sudo bash install | tee ~/acuparse.log`

## Licencing

This automated installer is licensed under the MIT license.

See [LICENSE](LICENSE) for more details.

## Release Notes

See [CHANGELOG.md](CHANGELOG.md) for detailed release notes.
