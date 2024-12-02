## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
# install.packages("STICr")  # if needed: install package from CRAN
# devtools::install_github("HEAL-KGS/STICr") # if needed: install dev version from GitHub
library(STICr)

## ----tidy-data----------------------------------------------------------------
# use tidy_hobo_data to load and tidy your raw HOBO data
df_tidy <-
  tidy_hobo_data(
    infile = "https://samzipper.com/data/raw_hobo_data.csv",
    outfile = FALSE, convert_utc = TRUE
  )

head(df_tidy)

## ----load-calibration-data----------------------------------------------------
# inspect the example calibration standard data provided with the package
data(calibration_standard_data)
head(calibration_standard_data)

## ----get-calibration----------------------------------------------------------
# get calibration
lm_calibration <- get_calibration(calibration_standard_data)
summary(lm_calibration)

## ----apply-calibration--------------------------------------------------------
# apply calibration
df_calibrated <- apply_calibration(
  stic_data = df_tidy,
  calibration = lm_calibration,
  outside_std_range_flag = T
)

head(df_calibrated)

## ----plot-calibrated-data, fig.width = 6, fig.height = 4----------------------
# plot SpC as a timeseries and histogram
plot(df_calibrated$datetime, df_calibrated$SpC,
  xlab = "Datetime", ylab = "SpC",
  main = "Specific Conductivity Timeseries"
)

hist(df_calibrated$SpC,
  xlab = "Specific Conductivity", breaks = seq(0, 1025, 25),
  main = "Specific Conductivity Distribution"
)

## ----classify-data------------------------------------------------------------
# classify data
df_classified <- classify_wetdry(
  stic_data = df_calibrated,
  classify_var = "SpC",
  threshold = 100,
  method = "absolute"
)
head(df_classified)

## ----plot-classified-data, fig.width = 6, fig.height = 4----------------------
# plot SpC through time, colored by wetdry
plot(df_classified$datetime, df_classified$SpC,
  col = as.factor(df_classified$wetdry),
  pch = 16,
  lty = 2,
  xlab = "Datetime",
  ylab = "Specific conductivity"
)
legend("topright", c("dry", "wet"),
  fill = c("black", "red"), cex = 0.75
)

## ----qaqc-data----------------------------------------------------------------
# apply qaqc function
df_qaqc <-
  qaqc_stic_data(
    stic_data = df_classified,
    spc_neg_correction = T,
    inspect_deviation = T,
    deviation_size = 4,
    window_size = 96
  )
head(df_qaqc)
table(df_qaqc$QAQC)

## ----validate-data, fig.width = 6, fig.height = 6-----------------------------
# load and inspect sample field observation data
head(field_obs)

# use validate_stic_data to compile closest-in-time STIC reading for each field observation
stic_validation <-
  validate_stic_data(
    stic_data = classified_df,
    field_observations = field_obs,
    max_time_diff = 30,
    join_cols = NULL,
    get_SpC = TRUE,
    get_QAQC = FALSE
  )

# we can now compare the field observations and classified STIC data in the table
head(stic_validation)

# calculate percent classification accuracy
sum(stic_validation$wetdry_obs == stic_validation$wetdry_STIC) / length(stic_validation$wetdry_STIC)

# compare SpC
plot(stic_validation$SpC_obs, stic_validation$SpC_STIC,
  xlab = "Observed SpC", ylab = "STIC SpC"
)

