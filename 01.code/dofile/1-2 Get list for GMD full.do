*! version 0.1.1  01Aug2024
*! Copyright (C) World Bank 2024
*! Minh Cong Nguyen - mnguyen3@worldbank.org

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.

//Load all data and check subnational data together with other data
clear all
tempfile data1 data2 data3 data4 class data1list data2a
global rnd AM2024

*global upath2 
global lnlist 2010 2021
global circa 3

local lnlist2 : subinstr global lnlist " " ",",all
global lnystart = min(`lnlist2')
global lnyend = max(`lnlist2')

*global lnystart 2010
*global lnyend 2010

//Load survey list
use "${upath2}\03.intermediate\Survey_varlist", clear
drop if code=="MDG" & year==2021
drop if code=="IRN" & year==2011 //no educat4
drop if code=="NGA" & year==2022
 
keep if use_microdata==1
*drop if strpos(survname,"-LIS")>0
drop ct_subnatid*

tempfile data1
save `data1', replace

keep code
duplicates drop code, force
save `data1list', replace

//get latest from data1
use `data1', clear
bys code: egen ymax = max(year)
keep if year == ymax
drop ymax
save `data2a', replace

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
collapse (sum) year*, by(code)

//add more years 
foreach ly1 of global lnlist { 
	local start `=`ly1'-${circa}'
	local end `=`ly1'+${circa}'
	forv ly =`start'(1)`end' {
		cap gen year`ly'=.
	}
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
*local start $lnystart
*local end $lnyend
foreach ly of global lnlist { 
*forv ly = `start'(1)`end' {
	use `data2', clear
	gen year = sel`ly'
	drop if year==.
	merge 1:1 code year using `data1'
	ta _merge
	keep if _merge==3
	drop _merge	
	gen type = 1
	save `data4', replace
	
	keep code
	duplicates drop code, force
	merge 1:1 code using `data1list'
	keep if _merge==2
	drop _merge
	
	merge 1:m code using `data1'
	keep if _merge==3
	drop _merge
	
	gen diff = abs(rep_year-`ly')
	bys code (rep_year): egen yrmin = min(diff)
	keep if diff==yrmin
	bys code (diff): egen yrmax = max(rep_year)
	gen yrm = rep_year ==yrmax
	drop if yrm==0
	drop yrm diff yrmin yrmax
	
	gen type = 2
	gen ln = `ly'
	append using `data4'
	la def type 1 "Within +-3 years" 2 "latest but not within +-3 years"
	la val type type	
	drop sel* over*
	sort code
	ren type surtype
	
	//add pop and hist income group of lineup year
	ren year datayear1
	gen year = `ly'
	
	//ASPIRE
	merge 1:1 code using "${upath2}\02.input\\`ly'\\ASPIRE_data_`ly'.dta", keepus(type _pop_All_SPL) 
	ren type type_aspire
	drop if _merge==2
	drop _merge
	
	//Findex
	merge 1:1 code using "${upath2}\02.input\\`ly'\\findex_`ly'_quintiles.dta", keepus(type)
	ren type type_findex
	drop if _merge==2
	drop _merge
	
	//UNESCO_cov_2021
	merge 1:1 code using "${upath2}\02.input\\`ly'\\UNESCO_cov_`ly'.dta", keepus(type)
	ren type type_unesco
	drop if _merge==2
	drop _merge
	
	//GED ==> review when it is 100
	merge 1:1 code using "${upath2}\02.input\\`ly'\\GED_cov_`ly'.dta", keepus(type)
	ren type type_ged
	drop if _merge==2
	drop _merge

	//JMP
	merge 1:1 code using "${upath2}\02.input\\`ly'\\JMP_cov_`ly'.dta", keepus(type)
	ren type type_jmp
	drop if _merge==2
	drop _merge
	
	//flag system: 1 in survey, 2 universal, 3 to fuse, 4 missing, cant fuse
	gen ct_sp = .
	gen ct_findex = ct_fin_account
	gen findex_flag = .
	gen edu_flag = .
	
	//universal
	gen All_SPL =round(_pop_All_SPL,1)
	replace sp_flag = 2 if All_SPL>=97 & All_SPL~=.
	replace sp_flag = . if (code=="COL"|code=="MEX"|code=="TUR") & All_SPL<97 //COL MEX is not universal
	
	replace ct_sp = 2 if sp_flag==2	
	replace ct_imp_wat_rec = 2 if water_flag==2
	replace ct_electricity = 2 if elec_flag==2
	
	//fused	
	replace water_flag=3 if type_jmp~="" & (ct_imp_wat_rec==0|ct_imp_wat_rec==.) 
	replace ct_imp_wat_rec = 3 if water_flag==3 & (ct_imp_wat_rec==0|ct_imp_wat_rec==.) 
	replace ct_imp_wat_rec = 2 if water_flag==2 & (ct_imp_wat_rec==0|ct_imp_wat_rec==.) 
	
	replace elec_flag=3 if type_ged~="" & (ct_electricity==0|ct_electricity==.) 
	replace ct_electricity = 3 if elec_flag==3 & (ct_electricity==0|ct_electricity==.) 
	replace ct_electricity = 2 if elec_flag==2 & (ct_electricity==0|ct_electricity==.) 
	
	replace sp_flag=3 if type_aspire~="" & (ct_sp==0|ct_sp==.) 
	replace ct_sp = 2 if sp_flag==2 & (ct_sp==0|ct_sp==.) 
	replace ct_sp = 3 if sp_flag==3 & (ct_sp==0|ct_sp==.)  
	
	replace findex_flag=3 if type_findex~="" & (ct_findex==0|ct_findex==.) 
	replace ct_findex = 2 if findex_flag==2 & (ct_findex==0|ct_findex==.)  
	replace ct_findex = 3 if findex_flag==3 & (ct_findex==0|ct_findex==.)   
	replace ct_findex = 2 if code=="LUX"
	replace findex_flag = 2 if code=="LUX"
	
	replace edu_flag=3 if type_unesco~="" & (ct_educat4==0|ct_educat4==.) 
	replace ct_educat4 = 2 if edu_flag==2 & (ct_educat4==0|ct_educat4==.)   
	replace ct_educat4 = 3 if edu_flag==3 & (ct_educat4==0|ct_educat4==.)   
	
	//Update flags
	replace edu_flag = 1 if edu_flag==. & ct_educat4==1
	replace water_flag = 1 if water_flag==. & ct_imp_wat_rec==1
	replace elec_flag = 1 if elec_flag==. & ct_electricity==1
	replace sp_flag = 1 if sp_flag==. & ct_sp==1
	replace findex_flag = 1 if findex_flag==. & ct_findex==1
	
	//todo when all variables are available, and surveys are within +-3, rep_year>= `ly' - ${circa} & rep_year<= `ly' + ${circa}
	gen todo = .
	replace todo = 1 if ct_poverty~=. & ct_imp_wat_rec~=. & ct_electricity~=. & ct_educat4~=. & ct_sp~=. & ct_findex~=. & (rep_year >= `ly' - ${circa} & rep_year <= `ly' + ${circa})
	
	drop ct_gaul_adm1_code ct_w_30m ct_roof ct_wall ct_floor groupcode groupname country ct_male ct_imp_san_rec All_SPL
	
	isid code
	order code year ct_* *_flag type_*
	compress
	
	saveold "${upath2}\02.input\\`ly'\\GMD_list_`ly'", replace
}
	
