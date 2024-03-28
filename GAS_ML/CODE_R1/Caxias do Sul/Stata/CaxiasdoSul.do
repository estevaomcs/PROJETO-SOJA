** CAXIAS DO SUL **
clear
use "C:\Users\PATH...\CaxiasdoSul.dta" 

** Organizing the Data ** 

label variable Weekbegin "Date of collection"
label variable Price "Gasoline sales price per liter"
label variable GasStationID "Gas Station Identifier"
label variable Cartel_CS "Dummy variable for cartel period"


* TABLE 1: SUMMARY STATISTICS FOR THE NUMBER OF GAS STATIONS IN THE SAMPLE - Caxias do Sul

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
summarize N_GasStation

*    Variable |        Obs        Mean    Std. Dev.       Min        Max
*-------------+---------------------------------------------------------
*N_GasStation |        484    25.89463    12.04612          4        116

* Hence, over the 484weeks in the sample, we collect data from 200 different Gas Stations. On average, the weekly data is based on the price of 25.89 gas stations**

*########################################################################################################################################################################
*########################################################################################################################################################################

**Generating the explanatory variables in new columns**

clear
use "C:\Users\PATH...\CaxiasdoSul.dta" 

label variable Weekbegin "Date of collection"
label variable Price "Gasoline sales price per liter"
label variable GasStationID "Gas Station Identifier"
label variable Cartel_CS "Dummy variable for cartel period"

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

keep Weekbegin Price_sd CV SPD Price_kurtosis Price_skewness N_GasStation Cartel_CS
order Weekbegin N_GasStation SPD Price_sd CV Price_skewness Price_kurtosis Cartel_CS


* Frequency of the cartel dummy variable - Cartel_DF
tabulate Cartel_CS

* TABLE 2: summary statistics for cartel and non-cartel periods - Caxias do Sul
bysort Cartel_CS: summarize SPD Price_sd CV Price_skewness Price_kurtosis


*GENERATE TABLE 3: STATISTICAL TESTS FOR THE SCREENS (MANN-WHITNEY AND KOLMOGOROV-SMIRNOV) - Caxias do Sul

* KOLMOGOROV-SMIRNOV
ksmirnov SPD , by (Cartel_CS)
ksmirnov Price_sd,  by (Cartel_CS)
ksmirnov CV , by (Cartel_CS)
ksmirnov Price_skewness , by (Cartel_CS)
ksmirnov Price_kurtosis , by (Cartel_CS)


*MANN-WHITNEY
ranksum SPD, by (Cartel_CS)
ranksum Price_sd,  by (Cartel_CS)
ranksum CV, by (Cartel_CS)
ranksum Price_skewness, by (Cartel_CS)
ranksum Price_kurtosis , by (Cartel_CS)

*########################################################################################################################################################################
*########################################################################################################################################################################

* STANDARDAZING THE DATA FOR APPLYING THE MACHINE LEARNING ALGORITHMS


* Standard Scale transformation for the explanatory variables - Caxias do Sul*


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
keep SPD_Norm CV_Norm Price_sd_Norm Price_skewness_Norm Price_kurtosis_Norm Cartel_CS
order SPD_Norm CV_Norm Price_sd_Norm Price_skewness_Norm Price_kurtosis_Norm Cartel_CS
rename (SPD_Norm CV_Norm Price_sd_Norm Price_skewness_Norm Price_kurtosis_Norm) (SPD CV Price_sd Price_skewness Price_kurtosis)

** saving as an excel file **
export excel using "C:\Users\path...\CaxiasdoSul_ML_Std.xls", firstrow(variables)

** The excel file CaxiasdoSul_ML_Std.xls is used to evaluate the machine learning algorithms (in PYTHON) **