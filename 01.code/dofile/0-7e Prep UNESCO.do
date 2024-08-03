//UNESCO
clear

*global upath2 

global circa 3
global input ${upath2}\02.input\

global lnystart 2021
global lnyend 2021

import excel using "${upath2}\02.input\UNESCO\UNESCO_Education_CompletedPrimaryorHigher.xlsx" , clear first
//TimePeriod	Value	Units	Nature	Location	Reporting Type	FootNote	Source	ISOalpha3

ren * , lower
ren completedprimaryeducationorh location 
ren countrycode code
drop if code==""
replace location = lower(location)
drop if location=="poorest quintile" | location=="richest quintile"
reshape long yr, i(country code location) j(year)
ren yr unesco
replace location = "_" + location
reshape wide unesco, i(country code year) j(location) string
drop if unesco_rural==. & unesco_total==. & unesco_urban==.
drop if unesco_total==. & (unesco_rural==. | unesco_urban==.)

saveold "${upath2}\02.input\UNESCO_data", replace
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
	replace type="Total" if unesco_total~=. & unesco_urban==. &  unesco_rural==.
	replace type="Urb_rur" if type==""  & unesco_urban~=. &  unesco_rural~=.
	replace type="Urb" if type==""  & unesco_urban~=. &  unesco_rural==.
	replace type="Rur" if type==""  & unesco_urban==. &  unesco_rural~=.
	isid code
	order code year unesco_total unesco_urban unesco_rural

	compress
	saveold "${upath2}\02.input\\`ly'\\UNESCO_cov_`ly'", replace
}
