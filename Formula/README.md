# Packaging for Mac OS (Homebrew)

This repository contains the code necessary to build packages for Mac OS using Homebrew.

## Environment setup

In order to use the formulas contained in this repository, you need to add a new tap to Homebrew. The command you need to run is

	brew tap huawei-hiq/hiq-deployment <URL>

where you need to replace `<URL>` with the URL of the present repository (e.g. https://code-cbu.huawei.com/huawei-hiq/hiq-deployment)

If you are stuck, the webpage https://docs.brew.sh/Taps has more details about taps in Homebrew.

## Install the package

Once you have properly setup the tap, installing the packages is as simple as issuing the following command

	brew install huawei-hiq/hiq-deployment/hiq-projectq
