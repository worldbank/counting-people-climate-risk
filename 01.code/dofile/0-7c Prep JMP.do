* Improved water by national quintile and rural/urban
clear

global circa 3
global input ${upath2}\02.input\

global lnystart 2021
global lnyend 2021

//Data
import excel using "${upath2}\02.input\jmp\data\jmp_clean.xlsx" , clear first sheet(estimates)
ren iso3 code
		
drop source w_imp_prem w_imp_av w_imp_qual w_sm
replace type = "_" + type
reshape wide w_imp w_bas, i(code year) j(type) string
	
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
	replace type="Total" if w_imp_total~=. & w_imp_urban==. &  w_imp_rural==.
	replace type="Urb_rur" if type==""
	isid code
	order code year w_imp_total w_imp_urban w_imp_rural w_bas_total w_bas_urban w_bas_rural

	compress
	saveold "${upath2}\02.input\\`ly'\\JMP_cov_`ly'", replace
}
	
