# rend.R - A shell-wrapper for rmarkdown::render

[TOC levels=3]: # " "
- [Usage](#usage)
- [Snippet Rendering](#snippet-rendering)
- [Installation](#installation)
- [How to run the unit-tests?](#how-to-run-the-unit-tests)
- [Frequently Asked Questions](#frequently-asked-questions)
- [How can I inline other images which are stored along with the code?](#how-can-i-inline-other-images-which-are-stored-along-with-the-code)
- [How to adress permission denied issues when rendering to sshfs-win mountpoints?](#how-to-adress-permission-denied-issues-when-rendering-to-sshfs-win-mountpoints)

Objective
> Render R scripts and Rmd documents easily using Rmarkdown from the terminal

## Usage

To use it from a shell you can call rend.R directly with a script as argument.
```
rend.R MyScript.R
```
or for Rmd
```
rend.R MyScript.Rmd
```


## Snippet Rendering

The report will be created in the current working directory. To learn about options just call `rend.R --help`

In case you want to render R snippets you can source a small bash function that wraps rend.R
```
source <(curl https://raw.githubusercontent.com/holgerbrandl/rendr/master/rendr_utils.sh 2>&1 2>/dev/null)
```
Now you can spin R snippets by piping them into `spinsnip`

```
echo "require(ggplot2); ggplot(iris, aes(Sepal.Length, Sepal.Width)) + geom_point()" | rendr_snippet "my_report"
```



## Installation

Download a local copy and add it to your path using
```
targetDirectory=~/bin/rendr
mkdir -p $targetDirectory
wget -NP $targetDirectory --no-check-certificate https://raw.githubusercontent.com/holgerbrandl/rendr/master/rend.R
chmod +x $targetDirectory/rend.R
echo 'export PATH='"$targetDirectory"':$PATH' >> ~/.bash_profile
```


## How to run the unit-tests?


To run the tests, just run the [`test_suite.sh`](test/test_suite.sh)

```bash

#We use https://github.com/lehmannro/assert.sh for the tests
which assert.sh || echo "assert.h is required!" 1>&2
#cd ~/bin && wget https://raw.githubusercontent.com/lehmannro/assert.sh/master/assert.sh && chmod u+x assert.sh

export RENDR_HOME="/d/projects/misc/rendr"

cd ${RENDR_HOME}

mkdir build
cd ${RENDR_HOME}/build

export PATH=${RENDR_HOME}:${PATH}

## double check that we're using the correct script
which rend.R


${RENDR_HOME}/test/test_suite.sh
```


## Frequently Asked Questions

## How can I inline other images which are stored along with the code?

To reference images that are part of the code (and thus not present int the directory into which the final report is rendered), the user may use `RENDR_SCRIPT_DIR` which is provided in by `rend.R` when rendering reports.


([complete](test/simple_report.R)) Example:
```r
1+1

#' ![image inlineing failed](`r file.path(RENDR_SCRIPT_DIR, "mqtt.png")`)
```

## How to adress permission denied issues when rendering to sshfs-win mountpoints?

Simply declare `export RENDR_PRECREATE_FIGURE_DIR=true` before running `rend.R`




