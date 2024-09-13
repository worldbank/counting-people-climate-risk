clear all
tempfile data1 data2 data3 data4 cpidata
global rnd AM2024
global rnd1 AM24

global circa 3
global lnystart 2021
global lnyend 2021
global lnvalues 215 365 685

//load cpi
*dlw, country(support) year(2005) type(gmdraw) filename(Final_CPI_PPP_to_be_used.dta) files surveyid(Support_2005_CPI_v11_M)
use "${upath2}\02.input\Final_CPI_PPP_to_be_used.dta", clear
gen lis = strpos(survname,"-LIS")>0
keep if lis==1
keep if inlist(code,"AUS","CAN","DEU","GBR","ISR","JPN","KOR","TWN", "USA")
save `cpidata', replace

//load pfw
*dlw, country(support) year(2005) type(gmdraw) filename(Survey_price_framework.dta) files surveyid(Support_2005_CPI_v11_M)
use "${upath2}\02.input\Survey_price_framework.dta", clear
gen lis = strpos(survname,"-LIS")>0
keep if lis==1
keep if inlist(code,"AUS","CAN","DEU","GBR","ISR","JPN","KOR","TWN", "USA")
gen code2 = ""
replace code2 = "au" if code=="AUS"
replace code2 = "ca" if code=="CAN"
replace code2 = "de" if code=="DEU"
replace code2 = "uk" if code=="GBR"
replace code2 = "il" if code=="ISR"
replace code2 = "jp" if code=="JPN"
replace code2 = "kr" if code=="KOR"
replace code2 = "tw" if code=="TWN"
replace code2 = "us" if code=="USA"
tostring year, gen(yr)
gen yr2 = substr(yr,3,2)
gen file = code2 + yr2
keep code year file survname rep_year ref_year comparability datatype survey_coverage
save `data1', replace

//get latest from data1
bys code: egen ymax = max(year)
keep if year == ymax
drop ymax
save `data2', replace

//2.figure out the selection for circa
use `data1', clear
su year,d
local miny = r(min)
local maxy = r(max)
forv y=`miny'(1)`maxy' {
	gen year`y'=.
	replace year`y'= 1 if year==`y'
}
drop year 
collapse (sum) year*, by(code datatype)

//add more years 
local start `=${lnystart}-3'
local end `=${lnyend}+3'
forv ly =`start'(1)`end' {
	cap gen year`ly'=.
}

//lineup year, select the same year first, then +-1, then +-2, then +-3, prefers the latest data first and closer, in that order

local start $lnystart
local end $lnyend
forv ly = `start'(1)`end' {	
	gen sel`ly' = `ly' if year`ly'==1
	//1 year
	replace sel`ly' = `=`ly'+1' if year`=`ly'+1'==1 & sel`ly'==.
	replace sel`ly' = `=`ly'-1' if year`=`ly'-1'==1 & sel`ly'==.
	//2 years
	replace sel`ly' = `=`ly'+2' if year`=`ly'+2'==1 & sel`ly'==.
	replace sel`ly' = `=`ly'-2' if year`=`ly'-2'==1 & sel`ly'==.	
	//3 year2
	replace sel`ly' = `=`ly'+3' if year`=`ly'+3'==1 & sel`ly'==.
	replace sel`ly' = `=`ly'-3' if year`=`ly'-3'==1 & sel`ly'==.	
}

//check overlapped 
local start `=${lnystart}+1'
local end ${lnyend}
forv ly = `start'(1)`end' {
	gen over`ly' = 1 if sel`ly'==sel`=`ly'-1' & sel`ly'~=. & sel`=`ly'-1'~=.
}
gen over${lnystart} = .
keep code datatype sel* over*
save `data3', replace

//add back to the data
local start $lnystart
local end $lnyend
forv ly = `start'(1)`end' {
	use `data3', clear
	gen ln = `ly'
	gen year = sel`ly'
	drop if year==.
	merge 1:1 code year datatype using `data1'
	ta _merge
	keep if _merge==3
	drop _merge
	gen type = 1
	save `data4', replace
	
	keep code
	duplicates drop code, force
	merge 1:1 code using `data2'
	drop if _merge==3 | _merge==1
	drop _merge
	gen type = 2
	gen ln = `ly'
	append using `data4'
	la def type 1 "Within +-3 years" 2 "latest but not within +-3 years"
	la val type type	
	drop sel* over*
	sort code
	//bring in cpi icp
	merge 1:1 code year survname using `cpidata', keepus(cpi2017 icp2017)
	keep if _merge==3
	drop _merge
	//bring in lineup values 215 and 685
	gen country_code = code
	ren year surv_year
	gen year = `ly'
	foreach ln of global lnvalues {
		merge 1:1 country_code year using "${upath2}\03.intermediate\PIPinput\PIP_`ly'_`ln'.dta", keepus(headcount)
		keep if _merge==3
		drop _merge	
		ren headcount pov`ln'
	}
	drop country_code year
	ren surv_year year
	//only keep wtihin +-3
	keep if type==1
	order code year file cpi2017 icp2017 pov215 pov365 pov685

	saveold "${upath2}\03.intermediate\Lineuplist\LISSY_ln_list_`ly'", replace
}
