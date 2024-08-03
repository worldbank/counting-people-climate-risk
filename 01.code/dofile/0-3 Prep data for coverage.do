//Data input for Coverage 
clear all
tempfile data1 data2 data3 data4 class
global rnd AM2024

*global upath2 

//load PIP pfw - one time.
/*
dlw, country(support) year(2005) type(gmdraw) filename(Survey_price_framework.dta) files surveyid(Support_2005_CPI_v11_M)
keep code year survname rep_year ref_year comparability datatype use_imputed use_microdata use_bin use_groupdata
isid code year survname 
save "${upath2}\02.input\Survey_price_framework.dta", replace
*/

//Income class
use "${upath2}\02.input\CLASS.dta", clear
keep if year_data==2022
save `class', replace

//GMD content file
use "${upath2}\02.input\GMD_variables_countAM24.dta", clear
isid surveyid mod
replace ct_w_30m  = ct_w_30mins if ct_w_30m==. & ct_w_30mins~=.
replace ct_w_30m  = ct_w_30min if ct_w_30m==. & ct_w_30min~=.

keep code year surveyid mod ct_urban ct_age ct_male ct_imp_wat_rec ct_imp_san_rec ct_electricity ct_educat4 ct_educat5 ct_educat7 ct_subnatid* ct_gaul_adm1_code ct_roof ct_wall ct_floor ct_w_30m ct_fin_account
bys surveyid (mod): gen nmod = _N

gen keep = 1 if nmod==1
replace keep = 1 if nmod==2 & mod=="ALL"
replace keep = 1 if nmod==3 & mod=="ALL"
keep if keep==1
split surveyid, parse("_")
ren surveyid3 survname
drop surveyid1-surveyid2 surveyid4-surveyid8
duplicates tag code year survname, gen(a)
drop if mod=="BIN" & a==1 & survname=="EU-SILC"
drop if mod=="HIST" & a==1 & code=="MYS" & year==2007
drop if mod=="BIN" & a==1 & code=="LCA" & year==2015
drop if mod=="HIST" & a==1 & code=="MEX" & year==1989
//to be update in AM24
drop if mod=="GPWG" & a==1 & code=="IRN" & year==2015
drop if mod=="GPWG" & a==1 & code=="IRN" & year==2016
drop if mod=="GPWG" & a==1 & code=="THA" & year==2009
//temporary drop until the data is available
drop if code=="MYS" & year==2022
drop if code=="KAZ" & year>=2019 & year<=2021

drop a nmod keep
isid code year survname
save `data2', replace

//need to update to v11/AM24
import excel using "${upath2}\\02.input\Subnational list - 0.xlsx" , first clear sheet("List")

drop if level==""
duplicates tag surveyid, gen(a)
drop if a==1 & lowest==""
drop a
isid surveyid
keep region code year surveyid mod level ct_*
split surveyid, parse("_")
ren surveyid3 survname
drop surveyid1-surveyid2 surveyid4-surveyid8

//drop duplicates (for subnational purposes)
drop if code=="THA" & year==2009 & mod=="GPWG"
isid code year survname
save `data3', replace

//load master
use "${upath2}\02.input\Survey_price_framework.dta", clear
keep code survname year rep_year ref_year comparability use_imputed use_microdata use_bin use_groupdata
merge 1:1 code year survname using `data2'
drop if _merge==2
drop _merge

merge 1:1 code year survname using `data3', keepus(level)
drop if _merge==2
drop _merge
order level, after(mod)

//drop countries with 2 welfare and no/not use subnat
drop if code=="AFG"
drop if code=="BRA" & (year>=2012 & year<=2015) & survname=="PNAD"
drop if code=="GBR" & survname=="EU-SILC"
drop if code=="BGR" & survname=="MTHS" & year==2007
drop if code=="EST" & survname=="HBS"
drop if code=="HUN" & (survname=="HBS" | survname=="THMS-LIS")
drop if code=="POL" & survname=="HBS"
drop if code=="LTU" & survname=="HBS"
drop if code=="LVA" & survname=="HBS"
drop if code=="SVK" & survname=="HBS"
drop if code=="ALB" & survname=="SILC-C"
drop if code=="HRV" & survname=="HBS"
drop if code=="MNE" & survname=="HBS"
drop if code=="ROU" & survname=="HBS"
drop if code=="TUR" & survname=="HICES" & (year==2017|year==2018|year==2019)
drop if code=="SRB" & survname=="EU-SILC" & (year>=2013 & year<=2020)
drop if code=="RUS" & survname=="VNDN"

//check one data per year
isid code year

//variables have value
ds3 ct_*
local vlist = r(varlist)
foreach var of local vlist {
	replace `var' = 1 if `var'>0 & `var'~=.
}

//EUSILC no subnat for 2022 rounds (Region will fix this)
drop if level=="" & survname=="EU-SILC"

//Universal coverage and High income assumptions
cap drop _merge
merge 1:1 code year using "${upath2}\02.input\WDI_elec_water.dta"
drop if _merge==2
drop _merge

cap drop _merge
merge 1:1 code year using "${upath2}\02.input\GED_data.dta"
drop if _merge==2
drop _merge

//unesco
cap drop _merge
merge 1:1 code year using "${upath2}\02.input\UNESCO_data.dta"
drop if _merge==2
drop _merge

//OECD
merge m:1 code  using "${upath2}\02.input\oecd_list.dta"
drop if _merge==2
drop _merge

//CLASS
merge m:1 code  using `class', keepus(incgroup_current)
drop if _merge==2
drop _merge

//flag: 1 avaiable, 2 fillin universal
cap gen elec_flag = .
//Impute electricity for some countries (universal coverage - 0 deprived)
replace elec_wdi = round(elec_wdi,1)
replace ged_total = round(ged_total,1)
replace ct_electricity = 1 if elec_wdi>=97 & elec_wdi~=. & ct_electricity==.
replace elec_flag = 2 if elec_wdi>=97 & elec_wdi~=.

replace ct_electricity = 1 if ged_total>=97 & ged_total~=. & ct_electricity==.
replace elec_flag = 2 if ged_total>=97 & ged_total~=.
replace elec_flag = 2 if (code=="TUR"|code=="SRB") & year>=2022

//MKD SRB BGR CZE EST HRV HUN LTU LVA SVK SVN UKR POL ROU TUR ARG AUT BEL CHE CYP DEU DNK ESP FIN FRA GBR GRC IRL ISL ITA LUX MLT NLD NOR PRT SWE

//Impute water for some countries (universal coverage - 0 deprived)
cap gen water_flag = .
replace wat_jmp = round(wat_jmp,1)
replace ct_imp_wat_rec = 1 if wat_jmp>=97 & wat_jmp~=. & ct_imp_wat_rec==.
replace water_flag = 2 if wat_jmp>=97 & wat_jmp~=.
replace water_flag = 2 if (code=="IRL" | code=="HRV")
/*
local water_list BGR CZE EST HRV HUN LVA SVK SVN AUT BEL CHE CYP DEU DNK ESP FIN FRA GBR GRC ISL ITA LUX MLT NLD NOR PRT SWE  //LTU:96 PAN 94 UKR 96 IRL 97.8
foreach c of local water_list {
	*replace dep_infra_impw2 = 0 if code=="UKR" //UKR special
	replace ct_imp_wat_rec = 1 if code=="`c'" & ct_imp_wat_rec==.
	replace water_flag = 1 if code=="`c'"
}
*/

//SP
gen sp_flag = .
replace sp_flag = 2 if oecd==1
replace sp_flag = 2 if sp_flag==. & incgroup_current=="High income"

//Findex
gen sp_findex = .
replace sp_findex = 2 if oecd==1
replace sp_findex = 2 if sp_findex==. & incgroup_current=="High income"
replace sp_findex = 2 if sp_findex==. & code=="LUX"

//impute LIS, and special CHN cases
foreach var of varlist ct_urban ct_age ct_male ct_educat4 ct_imp_wat_rec ct_electricity {
	replace `var' = 1 if `var'==. & strpos(survname,"-LIS")>0
	replace `var' = 1 if `var'==. & code=="CHN" & (year==2013|year==2018)
}
replace use_microdata = 1 if code=="CHN" & (year==2013|year==2018)
replace use_microdata = 1 if strpos(survname,"-LIS")>0
//special cases IND
foreach var of varlist ct_urban ct_age ct_male ct_imp_wat_rec ct_imp_san_rec ct_electricity ct_educat4 {
	replace `var' = 1 if `var'==. & code=="IND" & (year>=2019 & year<=2021)
}

//manual fix MDG2021 
foreach var of varlist ct_urban ct_age ct_male ct_imp_wat_rec ct_electricity ct_educat4 {
	*replace `var' = 1 if `var'==. & code=="MDG" & year==2021
	replace `var' = 1 if `var'==. & code=="CMR" & year==2021
	replace `var' = 1 if `var'==. & code=="NPL" & year==2022
}

gen ct_poverty = 1
order ct_poverty, after(level)

isid code year
ren year surv_year
clonevar year = rep_year
isid code year
order year, after(surv_year)
//fix
drop if code=="MYS" & year==2021
drop if code=="KAZ" & (year>=2019 & year<=2021)
compress

save "${upath2}\03.intermediate\Survey_varlist", replace