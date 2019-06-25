# #' ---
# #' title: "somthing cool"
# #' author: ""
# #' date: ""
# #' ---
#

# note: header has effect just when showing up on top.

#' # somthing

#' ## Data Preparation
# devtools::source_url("https://raw.githubusercontent.com/holgerbrandl/datautils/v1.54/R/core_commons.R")



# #' <style>
# #' .main-container {
# #' max-width: 1700px !important;
# #' }
# #' </style>

require(dplyr)

load_pack(lubridate)
load_pack(broom)
#' ## Data Preparation

# options(dplyr.width = 70) ## width
# options(tibble.width  = 300)
# options(tibble.width  = Inf)



print(getOption("width"))
print(getOption("tibble.width"))

bind_cols(iris,iris) %>% tbl_df
# mtcars %>% tbl_df

bind_cols(iris,iris) %>% tbl_df
#' ## Data Preparation

bind_cols(iris,iris) %>% tbl_df %>% rmarkdown::paged_table()

plot(1:10)