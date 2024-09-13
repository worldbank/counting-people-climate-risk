clear
version 18
global rnd AM24
global lnyear 2021
tempfile data1 data2 data3 fullctry missreg dataall dataall2 pop template
save `dataall', replace emptyok
save `dataall2', replace emptyok


global fileout Tables_CSC.xlsx
global fileout1 Tables_Country.xlsx
//import template 
import excel "${upath2}\\04.output\For CSC\CSC_Vision Indicator Template.xlsx", sheet(Vision Indicator Template) first
gen seq = _n
unab original : *
save `template', replace

//Population from PIP
use "${upath2}\\02.input\code_inc_pop_regpcn.dta", clear
keep if year==$lnyear
ren pop* pop*_pip
save `pop', replace

//Get total population for aggregates 
use "${upath2}\\04.output\For CSC\ctrylist.dta", clear
merge 1:1 code using `pop', keepus(pop*_pip)
ta _merge
drop _merge

gen reg_fy24= ""
replace reg_fy24 = "EAS" if region_fy24=="East Asia & Pacific"
replace reg_fy24 = "ECS" if region_fy24=="Europe & Central Asia"
replace reg_fy24 = "LCN" if region_fy24=="Latin America & Caribbean"
replace reg_fy24 = "MEA" if region_fy24=="Middle East & North Africa"
replace reg_fy24 = "NA" if region_fy24=="North America"
replace reg_fy24 = "SAS" if region_fy24=="South Asia"
replace reg_fy24 = "SSF" if region_fy24=="Sub-Saharan Africa"

gen inc_fy24 = ""
replace inc_fy24 = "HIC" if income_fy24=="High income"
replace inc_fy24 = "LIC" if income_fy24=="Low income"
replace inc_fy24 = "LMC" if income_fy24=="Lower middle income"
replace inc_fy24 = "UMC" if income_fy24=="Upper middle income"

gen obs = 1
save `data1', replace

//WLD
use `data1', clear
collapse (sum) pop_pip obs
gen group = "WLD"
gen section = "WLD"
save `dataall', replace

//Regions
use `data1', clear
collapse (sum) pop_pip obs, by(reg_fy24)
ren reg_fy24 group
gen section = "Region"
append using `dataall'
save `dataall', replace

//income groups
use `data1', clear
collapse (sum) pop_pip obs, by(inc_fy24)
gen section = "Income group"
ren inc_fy24 group
append using `dataall'
save `dataall', replace

//LDC
use `data1', clear
keep if ldc_fy24=="LDC"
collapse (sum) pop_pip obs
gen section = "LDC"
gen group = "LDC"
append using `dataall'
save `dataall', replace

//FCS
use `data1', clear
keep if fcs_fy24=="FCS"
collapse (sum) pop_pip obs
gen section = "FCS"
gen group = "FCS"
append using `dataall'
save `dataall', replace

//SST
use `data1', clear
keep if small_states_fy24=="SS"
collapse (sum) pop_pip obs
gen group = "SST"
gen section = "Small states"
append using `dataall'
save `dataall', replace

//SID
use `data1', clear
keep if sids_fy24=="SIDS"
collapse (sum) pop_pip obs
gen section = "SID"
gen group = "SID"
append using `dataall'
drop if group==""

ren pop_pip pop_full
ren obs obs_full
save `dataall', replace

//Raw exposure and vulnerable with all dimension (todo==1)
use "${upath2}\\04.output\Exp_vul_rai_${lnyear}_raw", clear
keep if scenario=="RP100*" & hazard=="any"
replace dep_educ_com = 0 if code=="KOR" & dep_educ_com==.

//todo = 1 is the list of countries with all dimensions, which is 104 countries.

//expose and vulnerable (both HH vulnerable and spatial vulnerable)
foreach var of varlist multvul_215 all2vul_215 multvul_365 all2vul_365 multvul_685 all2vul_685  {
	gen double `var'_exp = exprai_ + (exp_ - exprai_)*`var'	
}

foreach var of varlist poor215_ln poor365_ln poor685_ln dep_educ_com dep_infra_elec dep_infra_impw dep_sp dep_fin {
	gen double `var'_exp = (exp_ )*`var'	
}

// totalpop_rai: total population with spatial vulnerability
// exprai_ : exposed and spatial vulnerability

//WLD table
collect: table (scenario hazard), statistic(sum multvul_215_exp exp_   totalpop) nototal nformat(%4.2f)
collect style header scenario hazard , title(hide)
collect preview

su poor215_ln poor365_ln poor685_ln dep_educ_com dep_infra_elec dep_infra_impw dep_sp dep_fin [aw=sh_pop*pop_pip] if hazard=="any" & scenario=="RP100*"

*collapse (first) pop_pip (sum) multvul_215_exp exp_ totalpop, by(code)
collapse (first) pop_pip (rawsum) multvul_215_exp exp_ totalpop (mean) poor215_ln poor365_ln poor685_ln dep_educ_com dep_infra_elec dep_infra_impw dep_sp dep_fin [aw=sh_pop], by(code)
gen double rate = (multvul_215_exp/totalpop)*100

//same number as the WLD table
su rate [aw= totalpop]
su rate [aw= pop_pip]
ren pop_pip pop_pip_vul
save `data3', replace

//Ctry level number to CSC
gen ISO = code
ren rate YR2021
export excel code YR2021 using "${upath2}\\04.output\For CSC\\${fileout}", sheet(country_level) replace firstrow(variables) keepcellfmt
keep ISO YR2021
merge 1:1 ISO using `template', update replace
drop _merge
save `template', replace

use `data3', clear
export excel code rate poor215_ln poor365_ln poor685_ln dep_educ_com dep_infra_elec dep_infra_impw dep_sp dep_fin pop_pip_vul using "${upath2}\\04.output\For CSC\\${fileout1}", sheet(country_level) replace firstrow(variables) keepcellfmt
*save "c:\Temp\Am24", replace

//merge in the CSC listing
merge 1:1 code using `data1'
keep if _merge==3
drop _merge
save `data2', replace

//VUL rates
//WLD
use `data2', clear
collapse (rawsum) pop_pip obs (mean) rate [aw=pop_pip]
gen group = "WLD"
save `dataall2', replace

//Regions
use `data2', clear
collapse (rawsum) pop_pip obs (mean) rate [aw=pop_pip], by(reg_fy24)
ren reg_fy24 group
append using `dataall2'
save `dataall2', replace

//income groups
use `data2', clear
collapse (rawsum) pop_pip obs (mean) rate [aw=pop_pip], by(inc_fy24)
ren inc_fy24 group
append using `dataall2'
save `dataall2', replace

//LDC
use `data2', clear
keep if ldc_fy24=="LDC"
collapse (rawsum) pop_pip obs (mean) rate [aw=pop_pip]
gen group = "LDC"
append using `dataall2'
save `dataall2', replace

//FCS
use `data2', clear
keep if fcs_fy24=="FCS"
collapse (rawsum) pop_pip obs (mean) rate [aw=pop_pip]
gen group = "FCS"
append using `dataall2'
save `dataall2', replace

//SST
use `data2', clear
keep if small_states_fy24=="SS"
collapse (rawsum) pop_pip obs (mean) rate [aw=pop_pip]
gen group = "SST"
append using `dataall2'
save `dataall2', replace

//SID
use `data2', clear
keep if sids_fy24=="SIDS"
collapse (rawsum) pop_pip obs (mean) rate [aw=pop_pip]
gen group = "SID"
append using `dataall2'
drop if group==""

ren pop_pip pop_cov
ren obs obs_cov
save `dataall2', replace

merge 1:1 group using `dataall'
gen double pop_share = (pop_cov/pop_full)*100
drop _merge
sort section group
order section group pop_full obs_full rate pop_share pop_cov obs_cov
drop if group=="NA" & section=="Region"
drop if pop_share < 40
ren rate YR2021
export excel using "${upath2}\\04.output\For CSC\\${fileout}", sheet(agg_level, replace) firstrow(variables) keepcellfmt

ren group ISO
keep ISO YR2021
merge 1:1 ISO using `template', update replace
sort seq
order `original'
drop seq _merge
export excel using "${upath2}\\04.output\For CSC\\${fileout}", sheet(format, replace) firstrow(variables) keepcellfmt
