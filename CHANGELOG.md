# Acuparse Installer Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

## 2.0.3 - 2019-08-17

### Changed

- Removed phpmyadmin install

## 2.0.2 - 2019-08-04

### Changed

- Cleanup Variables and Exits

## 2.0.1 - 2019-07-28

### Changed

- Update docs path

## 2.0 - 2019-07-28

### Changed

- Support ONLY Debian/Rasbian Buster(10) and Ubuntu 18.04/19.04
- Update PHP migration script to support PHP7.3
- Scripts are now formatted to run with bash instead of sh.

### Notes

- Ubuntu 18.04/19.04 will use distro PHP7.2.
- Debian/Rasbian Buster will use distro PHP7.3.
- PHP7.3 script will update Ubuntu 18.04/19.04 to PHP7.3 using Sury repo.

## 1.2.4 - 2019-01-02

### Changed
- Update Copyright.

## 1.2.3 - 2018-12-01

### Fixed

- Newlines and PHP.
- Restart DB after creation.

## 1.2.2 - 2018-08-08

### Added

- Check timezone before installing.

## 1.2.1 - 2018-07-21

### Changed

- Added a2dismods for PHP 7.2 migration script.
- Formatting changes.

## 1.2.0 - 2018-07-06

### Changed

- Removed Ubuntu 16.04 LTS support and replaced with 18.04 LTS.
- Support for PHP 7.2.

## 1.1.0 - 2018-01-31

### Added

- SSL & Let's Encrypt Support.

## 1.0.1 - 2017-08-08

### Changed

- Removed Debian Jessie(8) support and replaced with Stretch(9).

## 1.0.0 - 2017-03-13

### Added

- Initial open source release.
