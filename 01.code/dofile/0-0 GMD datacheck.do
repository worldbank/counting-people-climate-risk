//Load all data and check subnational data together with other data
//sub* gaul*
//two steps

//1 - get variable availabiity 
//2

clear 
global rnd AM24

tempfile data1 data2
save `data2', replace emptyok

use "${upath2}\\02.input\repo_${rnd}all", clear
local all=_N
save `data1', replace

forv i=1(1)`all' {
	use `data1', clear
	
	local code = country[`i']
	local year = years[`i']
	local surveyid = surveyid[`i']
	local mod = module[`i']
	
	cap dlw, country(`code') year(`year') type(gmd) files nocpi mod(`mod') surveyid(`surveyid')	
	qui if _rc==0 {
		ds3
		local vlist = r(varlist)
		foreach var of local vlist {
			gen ct_`var' = ~missing(`var')
		}
		gen x = 1
		collapse (sum) ct_*
				
		gen code = "`code'"
		gen year = `year'
		gen surveyid = "`surveyid'"
		gen mod = "`mod'"
		
		append using `data2'
		save `data2', replace	
	}
}
use `data2', clear
save "${upath2}\\02.input\\GMD_variables_count${rnd}.dta", replace