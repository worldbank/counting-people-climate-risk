* Findex by national quintile and rural/urban (degurban, F2F only)
clear
tempfile data1 dataall
save `dataall', replace emptyok

global input ${upath2}\02.input\

*2021
use "${input}/Findex/WLD_2021_FINDEX_v03_M.dta", clear
ren economycode code
gen no_account = account==0 if !mi(account)
clonevar degurban = urbanicity_f2f
*replace degurban = 3 if mi(degurban)
*lab def rural_2021 3 "Total", add

tempfile data1
save `data1', replace

//quintile and urban/rural only
drop if degurban==.
gcollapse (mean) no_account [aw=wgt], by(economy code year inc_q degurban)
decode degurban, gen(lvl)
replace lvl = lower(lvl)
gen x = "q_urb_rur"
drop degurban
append using `dataall'
save `dataall', replace

//quintile only
use `data1', clear
gcollapse (mean) no_account [aw=wgt], by(economy code year inc_q)
gen lvl = "national"
gen x = "q"
append using `dataall'
save `dataall', replace

//national only
use `data1', clear
gcollapse (mean) no_account [aw=wgt], by(economy code year)
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
order economy code year no_accounttotal no_accountq*total *urban *rural

gen type = "Urb_rur" if no_accountq1urban~=. 
replace type = "Total" if no_accountq1total~=. & no_accountq1urban==. & type==""

isid code
compress
saveold "${input}/2021/findex_2021_quintiles.dta", replace
