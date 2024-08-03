//Data input for Coverage (water and JMP)
clear all
tempfile data1 data2 data3 data4
global rnd AM2024

*global upath2 

*ssc install wbopendata
// Access to electricity (% of population)
wbopendata, language(en - English) indicator(eg.elc.accs.zs) long clear 
ren eg_elc_accs_zs elec_wdi
ren countrycode code
keep code year elec_wdi
tempfile data1
save `data1', replace
 
import excel "${upath2}\02.input\jmp\data\jmp_clean.xlsx", sheet("estimates") firstrow clear
ren iso3 code
rename w_imp wat_jmp
keep if type == "total" 
keep code year wat_jmp
merge 1:1 code year using `data1'
keep if _merge==3
drop _merge

saveold "${upath2}\02.input\WDI_elec_water", replace


 
