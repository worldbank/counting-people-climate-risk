* Findex by national quintile and rural/urban (degurban, F2F only)
clear
tempfile data1 dataall
save `dataall', replace emptyok

// ssc install gtools
*global upath2 

global input ${upath2}\02.input\

*2011
use "${input}/Findex/WLD_2011_FINDEX_v02_M.dta", clear
ren ecnmycode code
gen no_account = (account==2|account==3) if !mi(account)
gen year = 2011
*clonevar degurban = urbanicity_f2f
*replace degurban = 3 if mi(degurban)
*lab def rural_2021 3 "Total", add

tempfile data1
save `data1', replace

//quintile only
use `data1', clear
collapse (mean) no_account [aw=wgt], by(economy code year inc_q)
gen lvl = "national"
gen x = "q"
append using `dataall'
save `dataall', replace

//national only
use `data1', clear
collapse (mean) no_account [aw=wgt], by(economy code year)
gen lvl = "national"
gen x = "nat"
append using `dataall'
save `dataall', replace

gen y = "total" if x=="nat"
replace y = "q"+string(inc_q)+"total" if x=="q"
replace y = "q"+string(inc_q)+lvl if x=="q_urb_rur"

replace no_account = no_account*100
drop lvl x  inc_q
reshape wide no_account , i( economy code year) j(y) string
order economy code year no_accounttotal no_accountq*total 

gen type = "Total" 
replace code = "COD" if code=="ZAR"
replace code = "XKX" if code=="KSV"
replace code = "ROU" if code=="ROM"
replace code = "PSE" if code=="WBG"
isid code
compress
saveold "${input}/2010/findex_2010_quintiles.dta", replace
