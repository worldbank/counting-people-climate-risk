*! version 0.1.1  01Aug2024
*! Copyright (C) World Bank 2024
*! Minh Cong Nguyen - mnguyen3@worldbank.org
*! Ben James Brunckhorst - bbrunckhorst@worldbank.org

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


clear
global rnd AM24
global lnyear 2021
tempfile data1 data2 data3 data4 fullctry missreg dataall
*global upath2 

*** EXPOSED DATA - onetime run
//1-ANY exposure + RAI
import delimited "${upath2}\\03.intermediate\Exposure\\${lnyear}\\am24exp_clean.csv", clear delim(",") asdouble varn(1)
drop if code=="" & geo_code==""
compress
save `data1', replace
saveold "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_raw", replace

//national
use `data1', clear
collapse (sum) totalpop* exp_*, by(code scenario)
gen dtype = "National"

ren exp*rai exprai*
ren exprai_drought_  exprai_drought
ren exprai_flood_  exprai_flood
ren exprai_heat_  exprai_heat
ren exprai_cyclone_  exprai_cyclone
ren exprai_any_ exprai_any

reshape long exp_ exprai_, i(code  scenario  totalpop dtype)  j(hazard) string
saveold "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_national", replace

//national - dou_code exposure
use `data1', clear
collapse (sum) totalpop* exp_*, by(code scenario dou_code)
gen geo_code = code + "_2020_WB0"
gen dtype = "National-dou"
saveold "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_natdou", replace

//national - dou_code pop 
*saveold "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_natdou_pop", replace

//area/national pop
use `data1', clear
collapse (sum) totalpop* exp_*, by(code  geo_code scenario)
gen dtype = "Area"
keep if scenario=="RP100*"
saveold "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_area_pop", replace

//national boundary
gen x = strpos(geo_code, "_WB0")>0
drop if x==1
drop x
collapse (sum) totalpop* exp_*, by(code scenario)
gen geo_code = code + "_2020_WB0"
append using "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_area_pop"
isid code geo_code
saveold "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_area_pop", replace

//area exposure
use `data1', clear
collapse (sum) totalpop* exp_*, by(code  geo_code scenario)
gen dtype = "Area"
ren exp*rai exprai*
ren exprai_drought_  exprai_drought
ren exprai_flood_  exprai_flood
ren exprai_heat_  exprai_heat
ren exprai_cyclone_  exprai_cyclone
ren exprai_any_ exprai_any

reshape long exp_ exprai_, i(code geo_code scenario  totalpop dtype)  j(hazard) string
saveold "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_area", replace

//2-dtypes
use "${upath2}\\03.intermediate\Survey_vul_${lnyear}", clear
keep code data data_group sample sh_pop geo_code
sort code geo_code data_group
bys code geo_code (data_group): egen t1 = total(sh_pop)
gen sh_urbrur = sh_pop/t1
drop t1 sh_pop data 

bys code (sample): gen t1 = _N
bys code sample (data_group): gen t2 = _N

//national boundary
gen x = strpos(geo_code, "_WB0")>0

gen dtype = "National" if t1==1
replace dtype = "Area" if t2==1 & dtype==""
replace dtype = "National-Urbrur" if t2==2 & dtype=="" & x==1
replace dtype = "Area-Urbrur" if t2==2 & dtype==""
*replace dtype = "National" if code=="URY" & geo_code=="URY_2020_WB0"
drop t1 t2 x

reshape wide sh_urbrur, i(code sample geo_code dtype) j( data_group ) string

saveold "${upath2}\\03.intermediate\Survey_dtype", replace

//3-Adjust urban-rural in exposed data (dtypes: National-Urbrur and Area-Urbrur)
//3a-Area-Urbrur
use "${upath2}\\03.intermediate\Survey_dtype", clear
keep if dtype=="Area-Urbrur"
drop sh_urbrurnational sh_urbrursubnat
merge 1:m code geo_code using "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_raw"
//check if there is no _merge==1
count if _merge==1
assert r(N)==0
drop if _merge==2
drop _merge
save `data4', replace

//3b-National-Urbrur
use "${upath2}\\03.intermediate\Survey_dtype", clear
keep if dtype=="National-Urbrur"
drop sh_urbrurnational sh_urbrursubnat
merge 1:m code geo_code using "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_natdou"
//check if there is no _merge==1
count if _merge==1
assert r(N)==0
drop if _merge==2
drop _merge
append using `data4'

sort code  geo_code scenario dou_code
bys code geo_code scenario (dou_code): egen pop_area = total(totalpop)
gen sh_pop_e = totalpop/pop_area
gen x = -1*dou_code
bysort code geo_code scenario (x): gen seq = _n
bysort code geo_code scenario (x): gen x1 = sum(sh_pop_e)
gen diff = sh_urbrurUrban-x1
gen urb = sh_urbrurUrban if seq==1 & diff<0

replace urb = sh_pop_e if diff>0 & diff~=.
bysort code geo_code scenario (x): gen x2 = sh_urbrurUrban-x1[_n-1] if diff<0
replace urb = x2 if x2<sh_pop_e & urb==. & x2>0 & x2~=.
replace urb = 0 if urb==.

//check urb
bysort code geo_code scenario (x): egen y = total(urb)
gen y1 = y- sh_urbrurUrban
su y1 //mean is 0.

gen rur = .
replace rur = sh_pop_e - urb if seq==1 & sh_pop_e>urb & rur==.
replace rur = sh_pop_e if urb==0
replace rur = sh_pop_e - x2 if x2>0 & x2~=. & rur==.
replace rur = 0 if rur==.

//check rur
bysort code geo_code scenario (x): egen z = total(rur)
gen d = y+z
su d //mean is 1

drop y y1 x1 diff x2 z d 

local vlist2 totalpop exp_drought exp_flood exp_heat exp_cyclone exp_any totalpop_rai exp_drought_rai exp_flood_rai exp_heat_rai exp_cyclone_rai exp_any_rai
foreach var of local vlist2 {
	gen `var'1 = `var'*urb/sh_pop_e
	gen `var'2 = `var'*rur/sh_pop_e
	drop `var'
}

drop sh_pop_e x seq pop_area

//collapse 7degurban into one level - 1 urban, 2 rural
collapse (sum) totalpop* exp_*, by(code geo_code scenario dtype)

reshape long totalpop totalpop_rai exp_drought exp_flood exp_heat exp_cyclone exp_any exp_drought_rai exp_flood_rai exp_heat_rai exp_cyclone_rai exp_any_rai, i(code geo_code scenario dtype) j(urbrur)
 
gen data_group = "Urban" if urbrur==1
replace data_group = "Rural" if urbrur==2
drop urbrur

order totalpop exp_drought exp_flood exp_heat exp_cyclone exp_any totalpop_rai exp_drought_rai exp_flood_rai exp_heat_rai exp_cyclone_rai exp_any_rai, after(data_group)

*gen dtype = "Area-Urbrur"
isid code geo_code scenario data_group
compress

ren exp*rai exprai*
ren exprai_drought_  exprai_drought
ren exprai_flood_  exprai_flood
ren exprai_heat_  exprai_heat
ren exprai_cyclone_  exprai_cyclone
ren exprai_any_ exprai_any

reshape long exp_ exprai_, i(code geo_code scenario data_group totalpop dtype)  j(hazard) string
saveold "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_urbrur", replace

*** EXPOSED DATA AND SURVEY
//4-Add missing areas in countries to the list - NOT SIMPLE as there is no correct POP share for the missing areas.
use "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\exp_dou_rai_raw", clear
keep code geo_code code
duplicates drop code geo_code, force
bys code (geo_code): gen x = _N

//drop country with no data
*drop if sample=="-1" & x==1
//country with some data
save `fullctry', replace

//Bring in missing areas in country with datam, assign national average numbers
use "${upath2}\\03.intermediate\Survey_vul_${lnyear}", clear
keep code geo_code
duplicates drop code geo_code, force
gen survey = 1
merge 1:1 code geo_code using `fullctry'
bys code: egen mn = mean(_merge)
keep if mn>2 & mn<3
drop if survey==1
drop x _merge mn
merge m:1 code using "${upath2}\\03.intermediate\Survey_vul_2021_national.dta"
drop if _merge==2
gen degurban = "national"
gen missing_area = "yes"
drop _merge survey

append using "${upath2}\\03.intermediate\Survey_vul_${lnyear}"

//Add in grid pop to rescale the population of missing areas and existing areas in the surveys
merge m:1 code geo_code using "${upath2}\\03.intermediate\Exposure\\${lnyear}\\exp_dou_rai_area_pop", keepus(totalpop)
//check if there is no _merge==1
count if _merge==1
assert r(N)==0

keep if _merge==3
drop _merge

bys code geo_code (data_group): gen seq = _N
bys code geo_code (data_group): replace totalpop = . if seq == 2 & _n==2
bys code: egen double t1 = total(totalpop)
bys code missing_area: egen double t2 = total(totalpop)

gen double t1area = t2*sh_pop if missing_area==""
replace t1area = totalpop if missing_area=="yes"

bys code: egen double t1check = total(t1area)
compare t1 t1check
gen double sh_pop_new = t1area/t1
drop t1 t1check t2 seq t1area
gen diff = sh_pop - sh_pop_new
ren sh_pop sh_pop_old
ren sh_pop_new sh_pop
drop diff totalpop
saveold "${upath2}\\03.intermediate\Survey_vul_${lnyear}_withmissing", replace

//Add exposed to Survey
tempfile data1 data2 data3 fullctry missreg dataall
use "${upath2}\\03.intermediate\Survey_vul_${lnyear}_withmissing", clear
*use "${upath2}\\03.intermediate\Survey_vul_${lnyear}", clear
sort code geo_code data_group

bys code (geo_code): gen t1 = _N
*bys code geo_code (data_group): gen t2 = _N
bys code geo_code (degurban): gen t2 = _N

gen x = strpos(geo_code, "_WB0")>0
gen dtype = "National" if t1==1
replace dtype = "Area" if t2==1 & dtype==""
replace dtype = "National-Urbrur" if t2==2 & dtype=="" & x==1
replace dtype = "Area-Urbrur" if t2==2 & dtype==""
drop t1 t2 x
save `data1', replace

//Urban-rural
use `data1', clear
keep if dtype == "Area-Urbrur" | dtype=="National-Urbrur"
merge 1:m code geo_code data_group using "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_urbrur"
ta _merge
keep if _merge==3
drop _merge
save `data2', replace

//area
use `data1', clear
keep if dtype == "Area"
merge 1:m code geo_code  using "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_area"
ta _merge
keep if _merge==3
drop _merge
append using `data2'
save `data2', replace

//national
use `data1', clear
keep if dtype == "National"
merge 1:m code   using "${upath2}\\03.intermediate\Exposure\\\${lnyear}\\\exp_dou_rai_national"
ta _merge
keep if _merge==3
drop _merge
append using `data2'
sort scenario code geo_code  data_group
save `data2', replace

//rescale pop to WDI/PIP
gen double s = pop_pip*sh_pop

//reestimate exp as share of population
local vlist totalpop_rai exp_ exprai_
foreach var of local vlist {
	replace `var'= (`var'/totalpop)*s
}

drop totalpop
ren s totalpop

saveold "${upath2}\\04.output\Exp_vul_rai_${lnyear}_raw_full", replace

//only countries with all dimensions
keep if todo==1
saveold "${upath2}\\04.output\Exp_vul_rai_${lnyear}_raw", replace