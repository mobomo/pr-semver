# PR Semver

[![CircleCI Build Status](https://circleci.com/gh/mobomo/pr-semver.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/mobomo/pr-semver) [![CircleCI Orb Version](https://badges.circleci.com/orbs/mobomo/pr-semver.svg)](https://circleci.com/orbs/registry/orb/mobomo/pr-semver) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/mobomo/pr-semver/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

This Orb exports as an env var the value of the next release tag based on PR labels.
By default if no tag found in the PR it will increase the `patch` version, you can add *minor* or *major* as PR label.
