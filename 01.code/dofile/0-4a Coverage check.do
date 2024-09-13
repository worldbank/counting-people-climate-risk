//Coverage table (in theory)
clear all
tempfile data1 data2 data3 data4 dataall
save `dataall', replace emptyok

global round AM24
global popf code_inc_pop_regpcn.dta

global lnystart 2010
global lnyend 2022

global circa 3
*global circa 1

//PIP region and WLD pop, pop_inc
use "${upath2}\\02.input\\${popf}" , clear
keep if year>=$lnystart &year<=$lnyend

gen pop_inc = pop*(incgroup_historical=="Low income"|incgroup_historical=="Lower middle income")
collapse (sum) pop pop_inc, by( year region_pip)
ren pop allpop_reg
ren pop_inc allpop_inc
tempfile datax
save `datax', replace
collapse (sum) allpop_reg allpop_inc, by( year)
gen region_pip = "WLD"
append using `datax'
save `datax', replace

//load survey list
use "${upath2}\03.intermediate\Survey_varlist", clear

clonevar datayear = year

//1.keep only year>=2012 for circa 2015 (-3) and above, add pcn_reg and pop, use reporting year
keep if datayear>= `=${lnystart}-${circa}'

//add pop, pcn_reg
merge 1:1 code year using "${upath2}\\02.input\\${popf}" , keepus(pop region_pip)
drop if _merge==2
ren pop pop_surv
drop _merge

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
	merge 1:1 code year using "${upath2}\\02.input\\${popf}" , keepus(pop incgroup_historical)
	ta _merge
	keep if _merge==3
	drop _merge
	
	gen pop_inc = pop*(incgroup_historical=="Low income"|incgroup_historical=="Lower middle income")	
	gen double overpop = pop if over`ly'==1
	gen double samelnypop = pop if datayear1==year 
	
	gen economy = 1
	tempfile data3
	save `data3', replace
	save "${upath2}\03.intermediate\Lineupcheck\Pov_cov_cir${circa}_lny`ly'", replace
	
	//WLD
	collapse (rawsum) pop pop_inc overpop samelnypop economy [aw=pop], by(year)
	gen region_pip = "WLD"
	la var pop "Population of lineup year (survey)"
	la var overpop "Population of overlapped lineup year (survey)"
	la var samelnypop "Population of same lineup year (survey)"
	append using `dataall'
	save `dataall', replace
	
	//pcn_reg
	use `data3', clear
	collapse  (rawsum) pop  overpop samelnypop economy [aw=pop] , by(year region_pip)
	append using `dataall'
	save `dataall', replace
	
}

use `dataall', clear

gen sh_newdata = 100*((pop-overpop)/ pop)
*gen sh_datainlny = 100*(samelnypop/ pop)
cap drop _merge
merge 1:1 year region_pip using `datax'
cap drop _merge
gen sh_datainlny = 100*(samelnypop/ allpop_reg)
gen sh_lmicpop = 100*(pop_inc/ allpop_inc)
gen sh_WLDpop = 100*(pop/allpop_reg)

la var sh_WLDpop "share of world pop"
la var sh_lmicpop "share of lic and lmic pop"
la var sh_newdata "share of new data compared to previous year"
la var sh_datainlny "share of data in the same year as lineup year"

save "${upath2}\03.intermediate\Lineupcheck\wld_pov_cov_circa${circa}", replace