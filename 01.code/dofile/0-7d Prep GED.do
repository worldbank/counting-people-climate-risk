//Electricity
clear

global circa 3
global input ${upath2}\02.input\

global lnystart 2021
global lnyend 2021

import excel using "${upath2}\02.input\GED\sdg7.1.1-access_to_electricity.xlsx" , sheet(UN reporting)  clear first
//TimePeriod	Value	Units	Nature	Location	Reporting Type	FootNote	Source	ISOalpha3

ren * , lower

ren timeperiod year 
ren isoalpha3 code
replace value = "" if value=="NaN"
destring value, replace
replace location = lower(location)
keep code year value location
replace location = "total" if location=="allarea"
replace location = "_" + location
drop if code=="NULL"
ren value ged
reshape wide ged, i(code year) j(location) string
saveold "${upath2}\02.input\GED_data", replace
tempfile data1
save `data1', replace

//2.figure out the selection for circa
su year,d
local miny = r(min)
local maxy = r(max)
forv y=`miny'(1)`maxy' {
	gen year`y'=.
	replace year`y'= 1 if year==`y'
}
drop year 
collapse (sum) year*, by(code)

//add more years 
local start `=${lnystart}-${circa}'
local end `=${lnyend}+${circa}'
forv ly =`start'(1)`end' {
	cap gen year`ly'=.
}

//lineup year, select the same year first, then +-1, then +-2, then +-3, prefers the latest data first and closer, in that order

local start $lnystart
local end $lnyend
forv ly = `start'(1)`end' {	
	gen sel`ly' = `ly' if year`ly'==1
	forv j=1(1)${circa} {
		//+ is prefered than -, and 1 is prefered than 2, so on
		replace sel`ly' = `=`ly'+`j'' if year`=`ly'+`j''==1 & sel`ly'==.
		replace sel`ly' = `=`ly'-`j'' if year`=`ly'-`j''==1 & sel`ly'==.
	}	
}

//check overlapped 
local start `=${lnystart}+1'
local end ${lnyend}
forv ly = `start'(1)`end' {
	gen over`ly' = 1 if sel`ly'==sel`=`ly'-1' & sel`ly'~=. & sel`=`ly'-1'~=.
}
gen over${lnystart} = .
keep code sel* over*
tempfile data2
save `data2', replace

//add back to the data so we can aggregate 
local start $lnystart
local end $lnyend
forv ly = `start'(1)`end' {
	use `data2', clear
	gen year = sel`ly'
	drop if year==.
	merge 1:1 code year using `data1'
	ta _merge
	keep if _merge==3
	drop _merge
	
	//add pop and hist income group of lineup year
	ren year datayear1
	gen year = `ly'
	
	gen type= ""
	replace type="Total" if ged_total~=. & ged_urban==. &  ged_rural==.
	replace type="Urb_rur" if type==""
	isid code
	order code year ged_total ged_urban ged_rural 

	compress
	saveold "${upath2}\02.input\\`ly'\\GED_cov_`ly'", replace
}
