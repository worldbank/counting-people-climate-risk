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

//CHN vul 2021

clear all
tempfile data1 data2 data3 data4 dataall
save `dataall', replace emptyok
            
*global upath2 
global sim 100

//Get from PIP for the lineup year 2021
local pov215 = 0.00
local pov365 = 0.0472
local pov685 = 17.0336

/* from DLW
levelnote	cpi2017	icp2017 (cpi is the same so one value)
rural	1.021	3.4950106
urban	1.021	4.3184844
*/
local cpi2017 = 1.021 
local icp2017urb = 4.3184844
local icp2017rur = 3.4950106

local code CHN
local lineupyear 2021
local baseyear 2018
local survname CHIP
local welfaretype CONS

****************************************************   
//Get values for fusion ASPIRE FINDEX 
//ASPIRE 
use "${upath2}\02.input\2021\ASPIRE_data_2021.dta", clear
keep if code=="`code'"
forv i=1(1)5 {
	local _pop_All_SPL_q`i'
} 
local aspire_sp	
count
if r(N)>0 {
	local aspire_sp	= 1
	forv i=1(1)5 {
		local _pop_All_SPL_q`i' = _pop_All_SPL_q`i'[1]
	}
} //rn
else {
	local aspire_sp = 0
}

//FINDEX data (no account, which is dep_fin)
use "${upath2}\02.input\2021\findex_2021_quintiles.dta", clear
keep if code=="`code'"
forv i=1(1)5 {	
	local no_accountq`i'total
} 

local findex	
count
if r(N)>0 {
	local findex	= 1
	forv i=1(1)5 {
		local no_accountq`i'total = no_accountq`i'total[1]
	}
} //rn
else {
	local findex = 0
}

****************************************************   
//Load microdata			
use "${upath2}\02.input\CHN\CHN_2018_CHIP.dta", clear

la def urban 1 "Urban" 0 "Rural"
la val urban urban
decode urban, gen(urb2)
gen reg_urb = subnatid + "*_*" + urb2
local subnatvar subnatid reg_urb

// welfare variable     		
gen gallT_ppp = welfare/`cpi2017'/`icp2017urb'/365    if urban==1
replace gallT_ppp = welfare/`cpi2017'/`icp2017rur'/365    if urban==0
replace gallT_ppp = 0.25 if gallT_ppp<0.25

****************************************************   
**Dimension 1:  Education   
****************************************************    
   
**1a) Indicator: no one in hh with primary completion (age 15+)   
//All adults   
global eduage 15   
local eduflag = 0   
cap gen educat5 = .   
cap gen educat7 = .   
   
cap su educat7   
if r(N)>0 {   
	gen temp2 = 1 if age>=$eduage & age~=. & educat7>=3 & educat7~=.   
	gen temp2c = 1 if age>=$eduage & age~=. & (educat7>=3 | educat7==.)   
}
else { //educat5   
	cap su educat5   
	if r(N)>0 {   
		gen temp2 = 1 if age>=$eduage & age~=. & educat5>=3 & educat5~=.   
		gen temp2c = 1 if age>=$eduage & age~=. & (educat5>=3 | educat5==.)   
	}
	else { //educat4   
		cap su educat4   
		if r(N)>0 {   
			gen temp2 = 1 if age>=$eduage & age~=. & educat4>=2 & educat4~=.   
			gen temp2c = 1 if age>=$eduage & age~=. & (educat4>=2 | educat4==.)   
		}
		else { //no education available    
			local eduflag = 1    
		}
	} //educat4   
}
   
if `eduflag'==0 {    
	gen temp2a = 1 if age>=$eduage & age~=.   
	bys hhid: egen educ_com_size = sum(temp2a)   
	bys hhid: egen temp3 = sum(temp2)   
	bys hhid: egen temp3c = sum(temp2c)   
	gen dep_educ_com = 0   
	replace dep_educ_com = 1 if temp3==0   
	gen dep_educ_com_lb = 0   
	replace dep_educ_com_lb = 1 if temp3c==0   
	ren temp3 educ_com_sum   
	ren temp3c educ_com_sum_lb   
	drop temp2 temp2a temp2c   
}
else { 
	gen dep_educ_com = .   
	gen dep_educ_com_lb = .   
	gen educ_com_sum = .   
	gen educ_com_sum_lb = .   
	gen educ_com_size = .    
}
   
gen educ_com_appl = 1   
replace educ_com_appl = 0 if (educ_com_size==0 | educ_com_size==.)   
gen temp2b = 1 if age>=$eduage & age~=. & educat4==. & educat5==. & educat7==.   
bys hhid: egen educ_com_mis = sum(temp2b)   
drop temp2b   
gen educ_com_appl_miss = educ_com_appl == 1 & educ_com_mis>0 & educ_com_mis~=.   
   
la var dep_educ_com "Deprived if Households with NO adults $eduage+ with no primary completion"   
la var dep_educ_com_lb "Deprived if Households with NO adults $eduage+ with no or missing primary completion"   
la var educ_com_appl "School completion is applicable households, has $eduage or more individuals"   
la var educ_com_appl_miss "School completion is applicable households but missing completion"   
cap drop  dep_educ_com_lb educ_com_appl educ_com_appl_miss

****************************************************   
**Dimension 2: Access to infrastructure    
****************************************************   

****************************************************   
//Indicator: Electricity   
cap des electricity
if _rc==0 gen dep_infra_elec = electricity==0 if electricity~=.
else gen dep_infra_elec = .
la var dep_infra_elec "Deprived if HH has No access to electricity"
 
****************************************************    
//Indicator: Water     
cap des imp_wat_rec
if _rc==0 gen dep_infra_impw = imp_wat_rec==0 if imp_wat_rec~=.
else      gen dep_infra_impw = . 
la var dep_infra_impw "Deprived if HH has No access to improved drinking water"
   
****************************************************   
**Dimension 3: Monetary    
****************************************************   
//recalculate the 2.15 line for 2.15 poverty
qui foreach num of numlist 215 365 685  {	
	if `pov`num''==0 {
		*local pline`num' = `=`num'/100'
		local pline`num' = 0.25
	}
	else {
		_pctile gallT_ppp [aw=weight_p], p(`pov`num'')
		local pline`num' = r(r1) 
	}
	
	gen poor`num'_ln = gallT_ppp < `pline`num'' if gallT_ppp~=.
	gen pline`num' = `pline`num''
	
} //num	

//Scaled IND to HH
//get 15+ population size by quintile or quintile/urban rural only when age is available.
forv a1=1(1)5 {
	local n15q`a1'total = 1
	local n15q`a1'urban = 1
	local n15q`a1'rural = 1
}

_ebin gallT_ppp [aw=weight_p], gen(q5ind) nq(5)		
cap des age
if _rc==0 {
	qui su age
	if r(N)>0 {
		gen tmp = age>=15 & age~=.
		bys hhid (pid): egen n15 = total(tmp)
		//`no_accountq`i'`nm'' `no_accountq`i'total'
		forv a1=1(1)5 {
			su n15 [aw=weight_p] if q5ind==`a1'
			local n15q`a1'total = r(mean)
			
			su n15 [aw=weight_p] if q5ind==`a1' & urban==1
			local n15q`a1'urban = r(mean)
			
			su n15 [aw=weight_p] if q5ind==`a1' & urban==0
			local n15q`a1'rural = r(mean)						
		} //a1
	} //rN
} //age
cap drop q5ind tmp n15

//Convert to HH   
bys hhid: egen double pop = total(weight_p)
duplicates drop hhid, force

clonevar weight_use = pop
	
//quintiles
_ebin gallT_ppp [aw=pop], gen(q5) nq(5)
gen g40 = q5==1|q5==2
gen test = 1
des,sh
tempfile databfsim
save `databfsim', replace

//loop through random assignments
	set seed 1234567
	clear
	tempfile ctry1 ctry1ln
	save `ctry1', replace emptyok
	save `ctry1ln', replace emptyok
	
	noi display _n(1)
	noi display in yellow "Number of simulations: $sim" _n(1)				
	noi mata: display("{txt}{hline 4}{c +}{hline 3} 1 " + "{hline 3}{c +}{hline 3} 2 " + "{hline 3}{c +}{hline 3} 3 " + "{hline 3}{c +}{hline 3} 4 " + "{hline 3}{c +}{hline 3} 5 ")
		
	qui forv sim=1(1)$sim {				
		use `databfsim', clear
				
		//findex access no_accountq`i'total
		if `findex'==1 {
			gen dep_fin = .
			forv i=1(1)5 {
				cap drop _a`i'
				if (`no_accountq`i'total' > 0) {				
					*wsample test [aw=pop] if q5==`i', percent(`no_accountq`i'total') newvar(_a`i') seed(`=1234567+`i'*`sim'') numsim(1)
					local adjfin = 100*((`=`no_accountq`i'total'/100')^(0.6*`n15q`i'total'))
					wsample test [aw=pop] if q5==`i', percent(`adjfin') newvar(_a`i') seed(`=1234567+`i'*`sim'') numsim(1)

				}
				else {
					gen _a`i' = 0 if q5==`i'				
				}
				replace dep_fin = _a`i' if q5==`i'
				drop _a`i'
			} //i
			gen fin_flag = 0				
		}
		else { //missing
			gen dep_fin = .
			gen fin_flag = 1
		}
		
		//SP access _pop_All_SPL_q`i'
		/*
		if `aspire_sp'==1 {	
			gen dep_sp = .
			forv i=1(1)5 {
				cap drop _a`i'
				if (`_pop_All_SPL_q`i'' > 0) {				
					wsample test [aw=pop] if q5==`i', percent(`_pop_All_SPL_q`i'') newvar(_a`i') seed(`=1234567+`i'*`sim'') numsim(1)
				}
				else {
					gen _a`i' = 0 if q5==`i'				
				}
				replace dep_sp = 1-_a`i' if q5==`i'
				drop _a`i'
			} //i
						
			gen sp_flag = 0
		}
		else { //missing
			gen dep_sp = .
			gen sp_flag = 1
		}
		*/
		//ASPIRE CHN2018 is universal now. 96.7
		gen dep_sp = 0
		
		//multidimensional vulnerability
		foreach num of numlist 215 365 685  {
			//vulnerable and one dim			
			gen pov1_edu_`num' = 0
			replace pov1_edu_`num' = 1 if poor`num'_ln==1 & dep_educ_com==1
			
			gen pov1_sp_`num' = 0
			replace pov1_sp_`num' = 1 if poor`num'_ln==1 & dep_sp==1
			
			gen pov1_fin_`num' = 0
			replace pov1_fin_`num' = 1 if poor`num'_ln==1 & dep_fin==1
			
			gen pov1_elec_`num' = 0
			replace pov1_elec_`num' = 1 if poor`num'_ln==1 & dep_infra_elec==1
			
			gen pov1_water_`num' = 0
			replace pov1_water_`num' = 1 if poor`num'_ln==1 & dep_infra_impw==1
			
			//rsum
			egen dim6_`num' = rowtotal(poor`num'_ln dep_educ_com dep_sp dep_fin dep_infra_elec dep_infra_impw), missing
			
			//any of the 6 dimensions - deprived in education; dep_sp; dep_fin
			gen multvul_`num' = 0
			replace multvul_`num' = 1 if dim6_`num'>=1 & dim6_`num'~=.
			
			// any 2, 3, 4,...,6
			forv j=2(1)6 {
				gen all`j'vul_`num' = 0
				replace all`j'vul_`num' = 1 if dim6_`num'==`j'
			}
		} //povlist
		gen _all_ = "All sample"

		gen sim = `sim'
		gen _count=1
		//collapse to get indicators
		compress
		tempfile data2
		save `data2', replace
		
		*local lvllist _all_ urban2 subnatid subnatid1 /*db040 */
		local lvllist _all_ urb2 `subnatvar'  
		qui foreach var of local lvllist {
			use `data2', clear
			clonevar h = pop
			*clonevar h_ln = pop
			*clonevar wta_pov = pop	
			replace `var' = stritrim(`var')
			replace `var' = ustrtrim(`var')
			
			levelsof `var', local(lvllist2)
			cap confirm string variable `var'
			if _rc==0 local st = 1
			else local st = 0
			
			qui groupfunction  [aw=pop], mean(gallT_ppp  poor* multvul_* all6vul_* all5vul_* all4vul_* all3vul_* all2vul_* dep_* pov1_* dim6*) rawsum(_count h) by(sim `var')
			
			
			rename gallT_ppp mean_ln
			ren _count nohh		
			ren h noind
			egen double totalhh = total(nohh)
			egen double totalind = total(noind)				
			gen sh_hh = nohh/totalhh
			gen sh_pop = noind/totalind
			
			ren `var' sample	
			gen level = "`var'"
			gen code = "`code'"
			gen lineupyear = `lineupyear'
			gen baseyear = `baseyear'
			gen survname = "`survname'"			
			gen str welfaretype = "`welfaretype'"
			
			append using `ctry1ln'			
			order code baseyear lineupyear survname welfaretype level sample sim mean_ln  poor* multvul_* all6vul_* all5vul_* all4vul_* all3vul_* all2vul_* dep_* pov1_* dim6* total* sh_* nohh noind
			save `ctry1ln', replace
		} //foreach subnat
		
		if (mod(`sim',50)==0){
			noi display in white ".  `sim'" _continue
			noi display _n(0)
		}
		else noi display "." _continue
	} //sim
	//collapse across sim
	
	//save results
	use `ctry1ln', replace
	save "${upath2}\03.intermediate\Sim\2021\temp\CHN_2018_CHIP_2021_lnsim", replace
	
	groupfunction, mean(poor* multvul_* all6vul_* all5vul_* all4vul_* all3vul_* all2vul_* dep_* pov1_* dim6* mean_ln total* sh_* nohh noind) by(code baseyear lineupyear survname level sample)
	
	order code survname level sample baseyear lineupyear mean_ln poor215_ln poor365_ln poor685_ln dep_* multvul_* all*vul* pov1* dim6* total* sh_* nohh noind
	gen todo = 1
	saveold "${upath2}\03.intermediate\Sim\2021\CHN_2018_CHIP_2021", replace
