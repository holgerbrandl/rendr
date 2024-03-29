#!/usr/bin/env Rscript

# similar http://stackoverflow.com/questions/10943695/what-is-the-knitr-equivalent-of-r-cmd-sweave-myfile-rnw

#http://stackoverflow.com/questions/3433603/parsing-command-line-arguments-in-r-scripts
#https://github.com/edwindj/docopt.R
#http://www.slideshare.net/EdwindeJonge1/docopt-user2014

## set a default cran r mirror  and customize environment
r = getOption("repos") # hard code the UK repo for CRAN 
r["CRAN"] = "http://ftp5.gwdg.de/pub/misc/cran/"
options(repos = r)
rm(r)

# load the docopt library
load_pack <- function(x, warn_conflicts=T){
    x <- as.character(substitute(x));

    # install.packages(x)
    if (! isTRUE(x %in% .packages(all.available = TRUE)) && any(available.packages()[, 1] == x)) {
        # update.packages(ask=F) # update dependencies, if any.
        eval(parse(text = paste("install.packages('", x, "')", sep = "")))
    }

    ## load it using a library function so that load_pack errors if package is still not ins
    eval(parse(text = paste("base::library(", x, ",  quietly=T, warn.conflicts=", warn_conflicts, ")", sep = "")))
}

load_pack("docopt")
load_pack("knitr")
load_pack("purrr")
load_pack("stringr")
load_pack("dplyr", warn_conflicts=F)
load_pack("tidyr")
load_pack("rmarkdown")

# disabled because user script will fail if they load plyr before dplyr
#suppressMessages(if (!require("dplyr")) install.packages("dplyr"))

## test invokation that mimics actual workflow: R --args -e "fsdf.R" "hello sdf" -e

## find the first r document and split up the arguments
allArgs = commandArgs(T)
rdocsInArgs = str_detect(allArgs, ".R$")

if (any(rdocsInArgs)) {
    rmdDocIndex <- min(which(rdocsInArgs))
    rendrArgs <- allArgs[0 : rmdDocIndex]
    scriptArgs <- allArgs[- (0 : rmdDocIndex)]
}else {
    rendrArgs <- allArgs
}


# retrieve and parse the command-line arguments
doc <- '
Use rmarkdown to render R and Rmd into html documents
Usage: rend.R [options] <r_script> [<quoted_script_args>]

Options:
-e                  Collapse code chunks
-c                  Cache results
-w                  Show warnings
-m                  Show Messages
--toc               Add a table of contents
--out <name>        Name of html report. By default the name of the R-script is used
--resprefix <name>  Sets a custom `results_prefix` variable for the script which can be used to prefix results
                    files. The default is the name of the R-script
--keep              Keep generated Rmd and md files
'

opts <- docopt(doc, args = rendrArgs)


r_script <- opts$r_script
keep_markdown_files <- as.logical(opts$keep)


if (! file.exists(r_script)) {
    stop(paste("file does not exist\n", doc))
}


## Create a temporary script in the current working directory to ensure that created resources plots etc can be inlined
## To allow for additional resources from the scripts directory to be inlined into the final documents, the directory
## of the script is exposed as a variable called RENDR_SCRIPT_DIR
## Note:## Using the script-home-dir as wd does not work because plot pngs would not make it into the final document. Also
## It's better to not clutter the directory containing the script since it might be under version control.



reportName = opts$out
prettyReportName = str_replace(str_replace(basename(r_script), ".R$", ""), ".Rmd$", "")
if (is.null(reportName)) {
    reportName = prettyReportName
}

# Precreate figure output on windows to work around sshfs-win issues
# if(Sys.info()["sysname"] == "Windows"){
# if(opts$`touch-figures`){
if (str_length(Sys.getenv("RENDR_PRECREATE_FIGURE_DIR")) > 0) {
    # dir.create(paste0(reportName, "_files"))
    dir.create(file.path(paste0(reportName, "_files"), "figure-html"), recursive = T)
}


## either use report-name as default `results_prefix` or user-provided one
if (! is.null(opts$resprefix)) {
    results_prefix = opts$resprefix
}else {
    results_prefix = prettyReportName
}

requiresSpinning = ! str_detect(r_script, ".Rmd$")

if (requiresSpinning) {

    ## To allow for additional resoucrces from the scripts directory to be inlined into the final documents, the directory
    ## of the script is exposed as a variable called RENDR_SCRIPT_DIR
    RENDR_SCRIPT_DIR=dirname(normalizePath(r_script))

    # use same name here since otherways caching does not seem to work
    #tmpScript <- tempfile(fileext=".R", tmpdir=getwd())
    tmpScript <- file.path(getwd(), paste0(".", reportName, ".R"))
    print(paste0("compiling tmp-script in ", tmpScript, "'"))

    script = readLines(r_script)

    # Extract title
    title = script %>%
        keep(~ str_starts(.x, fixed("#' # "))) %>%
        str_sub(5) %>%
        str_trim()

    if(length(title)==0 ) title=reportName


    # https://www.rdocumentation.org/packages/rmarkdown/versions/1.12/topics/output_metadata
    # output_metadata$set(
    #  title=title
    # )
    # does not seem have an effect --> it rather seems that the yaml header needs to come first in the document now
    # print(paste("ititle is ", title))

    ## add yaml header (will be ignored if already present
    metadata <- c(
    '#\' ---',
    paste0('#\' title: "', title, '"'),
    paste0('#\' author: "', Sys.getenv("USERNAME"), '"'),
    '#\' date: "_TODAY_"',
    '#\' ---',
    ''
    )

    script = c(metadata, script)

    widthAdjust = c(
    '',
    '#\' ',
    '#\' <style>',
    '#\' .main-container {',
    '#\' max-width: 1400px !important;',
    '#\' }',
    '#\' </style>',
    ''
    )

    script = c(widthAdjust, script)



    #system(paste("cat ", r_script," | sed 's/_TODAY_/'$(date +\"%m-%d-%Y\")'/g' | grep -Ev '^#+$' | grep -Fv '#!/usr/bin/env Rscript' >", tmpScript))

    ## remove shebang and comment-only lines from source document
    # script = c("#!/usr/bin/env Rscript", script)
    script = script %>% discard(~ str_detect(.x, fixed("#!/usr/bin/env")))

    ## remove separator lines
    # script = c("#' _TODAY_ '", script)
    script = script %>% discard(~ str_detect(.x, "^[#]+$"))

    # Replace _TODAY_
    script = script %>% map(~ str_replace(.x, "_TODAY_", as.character(Sys.Date())))

    ## Add markdown spacers before headers see header_after_md_text_fix.sh
    # system(paste("cat ", r_script," | sed 's/_TODAY_/'$(date +\"%m-%d-%Y\")'/g' | grep -Ev '^#####+$' | sed 's/#\\x27 #/#\\x27\\n\\n#\\x27 #/g' | grep -Fv '#!/usr/bin/env Rscript' >", tmpScript))
    # file.copy(r_script, tmpScript, overwrite = T)
    script = tibble(line = script) %>%
        mutate(prepend_line = pmap(., function(line){
            if (str_starts(line, fixed("#' #"))) c("#' ", line) else c(line)
        })) %>%
        unnest(prepend_line) %>%
        pull(prepend_line)


    #file.copy(r_script, tmpScript)
    writeLines(script, tmpScript)

    spin(tmpScript, knit=F)
    unlink(tmpScript)
    tmpScript= file.path(getwd(), paste0(".", reportName, ".Rmd"))

    # cat("\n", file = tmpScript, append = TRUE)
    # cat(metadata, file = tmpScript, append = TRUE)
}else {
    tmpScript = r_script
}


# see http://stackoverflow.com/questions/17341122/link-and-execute-external-javascript-file-hosted-on-github

#jsAddons <- tempfile(fileext=".js")
#cat("<script src='http://code.jquery.com/jquery-2.1.4.min.js' type='application/javascript'></script>", file=jsAddons)
#
#if(opts$e){
#    cat("<script src='http://cdn.rawgit.com/holgerbrandl/datautils/master/R/rendr/toggle_code_sections.js' type='application/javascript'></script>", file=jsAddons, append=T)
#}


## does not work yet
#cat("<style type='text/css'>
#.container-fluid {
#    max-width: 100% ;
##    color: blue;
#}
#</style>", file=jsAddons, append=T)
## to use --> provide as arg to html_document: pandoc_args=paste0("--include-in-header=", jsAddons)

#https://groups.google.com/forum/#!topic/knitr/ojcnq5Nm298

commandArgs <- function(trailingOnly = TRUE){ scriptArgs} ## note trailingOnly is simply ignored


#system(paste("cat ", r_script," | grep -Ev '^#+$' | grep -Fv '#!/usr/bin/env Rscript' >", basename(r_script)))
#r_script <- basename(r_script)

cacheResults = opts$c

## custom title http://stackoverflow.com/questions/14124022/setting-html-meta-elements-with-knitr
opts_chunk$set(
cache = cacheResults,
## note that cache.dir is overridden by rmarkdown (see https://github.com/rstudio/rmarkdown/blob/c46c780d1cea4ecb744bd448dc1247923ffbf529/R/render.R#L308
# cache.path = file.path(getwd(), paste0(reportName, "_cache/")),
message = opts$m,
warning = opts$w
# out.width='120%'
)


## alternatively we could use tmpScript <- tempfile(fileext=".R", tmpdir=".") but it would require addtional cleanup
knitr::opts_knit$set(
root.dir = getwd(),
# https://yihui.name/knitr/options/#package_options
width = 130
)
#
# if(opts$toc){ warning("adding toc config")
#     options( tibble.width = 170) ## max width when using toc
# } else{
#     options( tibble.width = 200) ## max width when using toc
# }


rmarkdown::render(input = tmpScript, output_file = paste0(reportName, ".html"),
output_format = rmarkdown::html_document(toc = opts$toc, toc_float = opts$toc, code_folding = if (opts$e)"hide" else "show", keep_md = keep_markdown_files, theme = "united", number_sections = T),
output_dir = getwd())

#spin(tmpScript, knit=T)

# if(!keep_markdown_files){
#    unlink(str_replace(basename(r_script), ".R", ".md"))
# }

## delete figures directory since all plots should be embedded anyway
#echo("deleteing", paste0(str_replace(basename(r_script), ".R", ""), "_files"))
if (! cacheResults) unlink(paste0(reportName, "_files"), recursive = T)

if (requiresSpinning) unlink(tmpScript)
