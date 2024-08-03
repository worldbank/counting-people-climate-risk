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

clear 
global rnd AM24

*global upath2 
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