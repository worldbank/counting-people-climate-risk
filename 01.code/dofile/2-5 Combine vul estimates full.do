clear all

//setting
global rnd AM24
global sim 100

global lnyear 2021

tempfile data1 pop geoiddata
save `data1', replace emptyok

//import standard geoid
import excel using "${upath2}\\02.input\SPID boundaries.xlsx", sheet("SPID boundaries") first clear	
gen sample_clean = ustrregexra(sample,`"[^a-zA-Z0-9]"',"")
replace sample_clean = upper(sample_clean)
isid code year survname sample_clean
save `geoiddata', replace

//Population from PIP
use "${upath2}\\02.input\code_inc_pop_regpcn.dta", clear
keep if year==$lnyear
ren pop* pop*_pip
save `pop', replace

//Combine data
local files : dir "${upath2}\\03.intermediate\Sim\\${lnyear}\" files "*.dta", nofail respect
qui foreach file of local files {
	use "${upath2}\\03.intermediate\Sim\\${lnyear}\\`file'", clear
	append using `data1'
	save `data1', replace
}

use `data1', clear
//update todo from LIS: AUS CAN DEU GBR ISR JPN KOR TWN USA
ta code if strpos(survname,"-LIS")>0 & todo==.

replace todo = 1 if strpos(survname,"-LIS")>0 & todo==.

replace nohh = _count if nohh==. & _count~=.
replace noind = h if noind==. & h~=.
drop h _count
replace noind = noind/1000000
drop if code=="GMB" & level=="region"
merge m:1 code using `pop', keepus(pop_pip pop_rural_pip pop_urban_pip)
drop if _merge==2
drop _merge
save `data1', replace

use `data1', clear
keep code
duplicates drop code, force
saveold "${upath2}\\03.intermediate\Data_vul_${lnyear}_codelist.dta" , replace

use `data1', clear
isid code survname level sample baseyear lineupyear
sort code survname level sample baseyear lineupyear
keep if level=="_all_"
saveold "${upath2}\\03.intermediate\Survey_vul_${lnyear}_national.dta" , replace

use `data1', clear
isid code survname level sample baseyear lineupyear
sort code survname level sample baseyear lineupyear
saveold "${upath2}\\03.intermediate\Survey_vul_${lnyear}_temp.dta" , replace

use  "${upath2}\\03.intermediate\Survey_vul_${lnyear}_temp.dta", clear
ren level byvar

//fix 4 countries
drop if code=="KOR" & sample==".*_*."
drop if code=="NLD" & sample=="1-." & byvar=="subnatid"
drop if code=="SVN" & byvar=="subnatid"
*drop if code=="SVN" & sample=="1-Si0"
drop if code=="TWN" & byvar=="reg_rural"

split sample , parse("*_*")
ren sample sample_org
ren sample2 data_group
ren sample1 sample
drop if sample=="MISSING"| sample=="NA" | sample=="Missing" | sample==""|sample==". –"|sample==".-"
replace sample = "5 - Littoral" if sample=="6 - Littoral" & code=="CMR"
replace sample = "10 - Maputo Province" if sample=="10 – Maputo Provincia" & code=="MOZ"
//conflict MAR
drop if (sample=="11 - Laayoune-Sakia Al Hamra"|sample=="12 - Dakhla-Oued Eddahab") & code=="MAR"
drop if sample=="67 – Sevastopol City" & code=="RUS"

replace byvar = "reg_rural" if (code=="CHN"|code=="IND") & byvar == "reg_urb"

gen data = ""
replace data = "All" if byvar=="_all_"
replace data = "All" if byvar=="urb2"
replace data = "Subnat" if byvar=="reg_rural"
replace data = "All" if data==""
drop if sample_org==".-*_*" | sample_org==".*_*." | sample_org==". – Not Applicable (No Stratification)*_*" | sample_org=="Missing" | sample_org=="*_*0"

replace data_group = "national" if byvar=="_all_"
replace data_group = "urbrur" if byvar=="urb2"
replace data_group = "subnat" if byvar=="subnatid" |byvar=="subnatid1"|byvar=="subnatid2"|byvar=="subnatidsurvey"|byvar=="gaul_adm1_str"|byvar=="gaul_adm1_code"

replace data_group = "Urban" if data_group=="1" & byvar=="reg_rural"
replace data_group = "Rural" if data_group=="0" & byvar=="reg_rural"

replace data_group = "Urban" if data_group=="1.Urban" & byvar=="reg_rural"
replace data_group = "Rural" if data_group=="0.Rural" & byvar=="reg_rural"

replace data_group = "subnat" if data_group=="." & data=="Subnat" & (code=="AUS" | code=="GBR" | code=="TWN")
replace data = "All" if (code=="AUS"|code=="GBR"|code=="TWN")

//Country with national level only (even when subnation is available but not representative)
drop if (code=="HND"|code=="JAM"|code=="TWN") & data=="Subnat"
drop if (code=="HND"|code=="JAM"|code=="TWN") & data=="All" & data_group=="subnat"
*ECU
drop if code=="IND" & data=="All" & data_group=="subnat"
drop if code=="PAN" & data=="All" & data_group=="subnat"

//drop obs with missing data_group, selected countries
drop if data_group=="." & data=="Subnat" & (code=="USA")
drop if data_group=="" & data=="Subnat" & (code=="UKR")
drop if data_group=="" & data=="Subnat" & (code=="PSE")
drop if data_group=="" & data=="Subnat" & (code=="NAM")

order code data data_group sample
sort code data data_group sample

bys code sample: gen ct = _N
drop if ct==3 & data=="All"

bys code data (sample): gen ct2 = _N
bys code: gen y = _N
drop if ct2==1 & data=="All" & y~=1
drop if (ct2==2|ct2==3) & data=="All" & ct~=3
bys code (byvar): egen ng = nvals(data_group)
drop if ng==2 & data_group=="national"

drop if code=="IND" & (byvar=="urb2"|byvar=="_all_")
drop if code=="KAZ" & byvar=="subnatid" & data=="All"
drop if code=="LKA" & data=="All" & (byvar=="_all_"|byvar=="subnatid2")
drop if code=="ISR" & sample=="[70]Yehuda and Shomron"

drop if code=="MWI" & data=="All" & (byvar=="subnatid2"|byvar=="_all_")
drop if code=="PAN" & data=="All" & (byvar=="_all_")
drop if code=="TUR" & data=="All" & (byvar=="_all_")
drop if code=="MDV" & data_group=="national" & baseyear==2019

drop if code=="MDV" & data=="Subnat" & baseyear==2019
drop if code=="TON" & data_group=="national" & baseyear==2021
drop if code=="TON" & data_group=="subnat" & baseyear==2021

//not sure sample
drop if code=="IND" & sample=="Telangana"

//fix data with more than 2 data groups
bys code: egen ndata1 =nvals(data)
ta code data if ndata1==2
drop if ndata1==2 & data=="All" & (code=="BWA" |code=="COG")
drop if ndata1==2 & data=="All" & (code=="ESP" |code=="KGZ")
drop if ndata1==2 & data=="All" & (code=="MUS" |code=="RWA")
drop if ndata1==2 & data=="All" & (code=="SYC" |code=="VUT")
drop if ndata1==2 & data=="All" & (code=="WSM")

//merge with geoid data
replace year = baseyear if year==.
gen sample_clean = ustrregexra(sample,`"[^a-zA-Z0-9]"',"")
replace sample_clean = upper(sample_clean)

merge m:1 code year survname sample_clean using  `geoiddata', keepus(geo_code geo_code2_new)
drop if _merge==2
drop _merge
sort  code data sample data_group

//Add geocode manually
bys code: gen ct0=_N
levelsof code if ct0==1,local(adm0list)
dis `"`adm0list'"'
foreach c1 of local adm0list {
	replace geo_code = "`c1'_2020_WB0" if ct0==1 & code=="`c1'" & geo_code==""
}

//ctry with urban/rural at national level
local ctrynat1 CHE CYP DNK EST GAB GRD GTM HRV IRL ISL KIR KOR LCA LTU LUX LVA MHL NOR PRT SVK SVN TON TUR TUV URY ECU SSD
foreach c1 of loca ctrynat1 {
	replace geo_code = "`c1'_2020_WB0" if code=="`c1'" & geo_code=="" & ct0==2
}

drop ct ct2 ng y ct0 ndata1
bys code geo_code: gen x = _N

gen degurban = ""
replace  degurban = data_group if x==2 
replace  degurban = "national" if x==1
replace degurban = lower(degurban)
drop x

bys code: egen double x1 = total(nohh)
bys code: egen double x2 = total(noind)
ren sh_hh sh_hh1
ren sh_pop sh_pop1
gen double sh_hh = nohh/x1
gen double sh_pop = noind/x2
drop x1 x2

sort code data sample data_group 

isid geo_code degurban
*br code data sample data_group geo* degurban baseyear todo

saveold "${upath2}\\03.intermediate\Survey_vul_${lnyear}", replace