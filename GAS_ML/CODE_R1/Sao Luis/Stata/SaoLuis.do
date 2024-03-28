** SAO LUIS **
clear
use "C:\Users\PATH...\SaoLuis.dta" 

** Organizing the Data ** 

label variable Weekbegin "Date of collection"
label variable Price "Gasoline sales price per liter"
label variable GasStationID "Gas Station Identifier"
label variable Cartel_SL "Dummy variable for cartel period"


* TABLE 1: SUMMARY STATISTICS FOR THE NUMBER OF GAS STATIONS IN THE SAMPLE - SAO LUIS

**To preserve the identity of the gas stations, we randomly assign numbers in an ascending order to tag them. 
**Thus, tabulating GasStationId gives us the total number of Gas Stations in the evaluated period.

tabulate GasStationID

** From the above, we have 996 gas stations identified in our sample. Note that their relative frequency significantly varies. 

** Creating a variable to compute the number of Gas Stations on a weekly basis **

gen id = 1
egen group = group (Weekbegin)
sort group
by group: gen GasStation = sum(id)
egen N_GasStation = max(GasStation), by (Weekbegin)

*As we compute all the four statistical moments of the gasoline sales price, we need to drop weeks with less than 4 observations (gas stations) 

* as we use the kurtosis as explanatory variables, we drop the weeks in which the number of gas station is < 4 

duplicates drop Weekbegin, force
drop if N_GasStation < 4
summarize N_GasStation

*    Variable |        Obs        Mean    Std. Dev.       Min        Max
*-------------+---------------------------------------------------------
*N_GasStation |        449    41.55234    11.84168          4        127

* Hence, over the 449 weeks in the sample, we collect data from 208 different Gas Stations. On average, the weekly data is based on the price of 41.55 gas stations**

*########################################################################################################################################################################
*########################################################################################################################################################################

**Generating the explanatory variables in new columns**

clear
use "C:\Users\PATH...\SaoLuis.dta" 

label variable Weekbegin "Date of collection"
label variable Price "Gasoline sales price per liter"
label variable GasStationID "Gas Station Identifier"
label variable Cartel_SL "Dummy variable for cartel period"

**As we compute all the four statistical moments of the gasoline sales price, we need to drop the week with less than 4 observations (gas stations) 
** Creating a variable to compute the number of Gas Stations on a weekly basis **

gen id = 1
egen group = group (Weekbegin)
sort group
by group: gen GasStation = sum(id)
egen N_GasStation = max(GasStation), by (Weekbegin)

drop if N_GasStation < 4

*Auxiliary variables to calculate the Spread*

egen rank_lo = rank (Price), by (Weekbegin) unique
egen rank_hi = rank(-Price), by (Weekbegin) unique
egen HigherPrice = max(Price), by (Weekbegin)
egen LowerPrice  = min(Price), by (Weekbegin)


** Computing the Mean, Standard Deviation, Skewness and Kurtosis of the gasoline sales price (by Weekbegin) ** 

ssc install rangestat

rangestat (mean) Price (sd) Price (skewness) Price (kurtosis) Price , interval(id 0 2) by (Weekbegin)
 
 
 ** Computing the Coefficient of Variation (CV) **
 
gen CV = Price_sd/ Price_mean
 

** Computing the SPREAD **

gen SPD = ( HigherPrice - LowerPrice) / LowerPrice

* drop duplicate lines

duplicates drop Weekbegin, force

* checking for missings:

drop if SPD==.
drop if Price_sd==.
drop if CV==.
drop if Price_skewness ==.
drop if Price_kurtosis ==.

* Cleaning the database

keep Weekbegin Price_sd CV SPD Price_kurtosis Price_skewness N_GasStation Cartel_SL
order Weekbegin N_GasStation SPD Price_sd CV Price_skewness Price_kurtosis Cartel_SL


* Frequency of the cartel dummy variable - Cartel_SL
tabulate Cartel_SL

* TABLE 2: summary statistics for cartel and non-cartel periods - Sao Luis

bysort Cartel_SL: summarize SPD Price_sd CV Price_skewness Price_kurtosis


*GENERATE TABLE 3: STATISTICAL TESTS FOR THE SCREENS (MANN-WHITNEY AND KOLMOGOROV-SMIRNOV) - Sao Luis

* KOLMOGOROV-SMIRNOV
ksmirnov SPD , by (Cartel_SL)
ksmirnov Price_sd,  by (Cartel_SL)
ksmirnov CV , by (Cartel_SL)
ksmirnov Price_skewness , by (Cartel_SL)
ksmirnov Price_kurtosis , by (Cartel_SL)


*MANN-WHITNEY
ranksum SPD, by (Cartel_SL)
ranksum Price_sd,  by (Cartel_SL)
ranksum CV, by (Cartel_SL)
ranksum Price_skewness, by (Cartel_SL)
ranksum Price_kurtosis , by (Cartel_SL)

*########################################################################################################################################################################
*########################################################################################################################################################################

* STANDARDAZING THE DATA FOR APPLYING THE MACHINE LEARNING ALGORITHMS


* Standard Scale transformation for the explanatory variables - Sao Luis*


*Spread
egen MeanSPD = mean(SPD)
egen StdSPD = sd(SPD)
gen SPD_Norm = (SPD - MeanSPD)/StdSPD
histogram SPD_Norm

*Standard deviation
egen MeanPrice_sd = mean(Price_sd)
egen StdPrice_sd = sd(Price_sd)
gen Price_sd_Norm = (Price_sd - MeanPrice_sd) / StdPrice_sd
histogram Price_sd_Norm

*Coefficient of Variation
egen Mean_CV = mean(CV)
egen Std_CV = sd(CV)
gen CV_Norm = (CV - Mean_CV) / Std_CV
histogram CV_Norm


*Skewness
egen Mean_Skew = mean(Price_skewness)
egen Std_Skew = sd(Price_skewness)
gen Price_skewness_Norm = (Price_skewness - Mean_Skew) / Std_Skew
histogram Price_skewness_Norm

*kurtosis
egen Mean_Kurt = mean(Price_kurtosis)
egen Std_Kurt = sd(Price_kurtosis)
gen Price_kurtosis_Norm = (Price_kurtosis - Mean_Kurt) / Std_Kurt
histogram Price_kurtosis_Norm

*Organizing the dataset
keep SPD_Norm CV_Norm Price_sd_Norm Price_skewness_Norm Price_kurtosis_Norm Cartel_SL
order SPD_Norm CV_Norm Price_sd_Norm Price_skewness_Norm Price_kurtosis_Norm Cartel_SL
rename (SPD_Norm CV_Norm Price_sd_Norm Price_skewness_Norm Price_kurtosis_Norm) (SPD CV Price_sd Price_skewness Price_kurtosis)

** saving as an excel file **
export excel using "C:\Users\path...\SaoLuis_ML_Std.xls", firstrow(variables)

** The excel file SaoLuis_ML_Std.xls is used to evaluate the machine learning algorithms (in PYTHON) **