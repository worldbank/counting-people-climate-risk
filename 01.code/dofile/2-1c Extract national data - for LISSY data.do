//Extract national data LIS txt file
clear
version 18

global datain "${upath2}\03.intermediate\LISoutput\"

global rnd AM2024
global lnyear 2021

//update the filename here for each year after each run in LISSY
global f2021 "LIS nat 2021 listing_job_1245381.txt"
global f2010 "LIS nat 2010 listing_job_1245384.txt"

local date = c(current_date)
local time = c(current_time)
local user = c(username)

//number of tables for each data point
local ntable 11
forv x=1(1)`ntable' {
	tempfile c`x'
	save `c`x'', replace emptyok
}

//import data
import delimited using "${datain}\\${f${lnyear}}" , clear
gen drop = regexm(v1, "-{10,}")
drop if drop ==1	 
drop drop
replace v1 = trim(v1)
gen v3 = v2
split v3, parse("")
gen x = strpos(v1, "-------------")
drop if x>0 & x~=.
drop x
gen x1 = strpos(v1, "(")
gen x2 = strpos(v1, ")")
gen x3 = strpos(v1, "[")
gen x4 = strpos(v1, "]")

drop if x1> 0 & x2>0 & x3==0 & x4==0 & v2==""
drop x2 x1 x3 x4

//identify table
gen c1 = strpos(v2, "mean(welfare)")
gen c2 = strpos(v2, "mean(dep_edu~m)")
gen c3 = strpos(v2, "mean(poor215~n)")
gen c4 = strpos(v2, "mean(p1_ed~215)")
gen c5 = strpos(v2, "mean(all2v~215)")
gen c6 = strpos(v2, "mean(poor365~n)")
gen c7 = strpos(v2, "mean(p1_ed~365)")
gen c8 = strpos(v2, "mean(all2v~365)")
gen c9 = strpos(v2, "mean(poor685~n)")
gen c10 = strpos(v2, "mean(p1_ed~685)")
gen c11 = strpos(v2, "mean(all2v~685)")

gen len = length(v1)
gen p4s = strpos(v1, "-")

split v1 if len==15 & p4s==4, parse("-")
gen seq = _n
gen seq2 = seq if v11~=""
gen cum = sum(seq2)

tempfile data1
save `data1',replace
levelsof cum, local(lista)
foreach lvl of local lista {
	use `data1', clear
	keep if cum==`lvl'
	ren v11 code
	ren v12 year
	ren v13 file
	replace code = code[1]
	replace year = year[1]
	replace file = file[1]
	gen gr = c1+c2+c3+c4+c5+c6+c7+c8+c9+c10+c11
	gen gr2 = sum(gr)
	drop if gr2==0
	levelsof gr2, local(listb)
	
	tempfile datax
	save `datax', replace
	local i = 0
	foreach gr of local listb {
		use `datax', clear
		keep if gr2==`gr'
		local i = `i'+1
		drop if v31==""
		
		if v31[1]== "mean(welfare)" { //c1
			drop if v31=="mean(welfare)" 
			ren v1 area			
			ren v31 welfare 
			ren v32 dep_infra_elec
			ren v33 dep_infra_impw 
			ren v34 dep_fin
			ren v35 dep_sp
			keep area code year file welfare dep_infra_elec dep_infra_impw dep_fin dep_sp
			destring welfare welfare dep_infra_elec dep_infra_impw dep_fin dep_sp, replace
			replace area = trim(area)
			recast str area
			append using `c1'
			save `c1', replace
		}		
		else if v31[1]== "mean(dep_edu~m)" { //c2 
			drop if v31== "mean(dep_edu~m)"
			ren v1 area
			ren v31 dep_educ_com 
			ren v32 _count
			ren v33 h			
			keep area code year file dep_educ_com _count h 
			destring dep_educ_com _count h, replace
			replace area = trim(area)
			recast str area
			append using `c2'
			save `c2', replace
		}	
		//215
		else if v31[1]== "mean(poor215~n)" { //c3	
			drop if v31== "mean(poor215~n)"
			ren v1 area
			ren v31 poor215_ln
			ren v32 dim6_215
			ren v33 multvul_215			
			keep area code year file poor215_ln dim6_215 multvul_215
			destring poor215_ln dim6_215 multvul_215, replace
			replace area = trim(area)
			recast str area
			append using `c3'
			save `c3', replace
		}	
		else if v31[1]== "mean(p1_ed~215)" {	 //c4		
			drop if v31== "mean(p1_ed~215)"
			ren v1 area						
			ren v31 p1_edu_215 
			ren v32 p1_sp_215
			ren v33 p1_fin_215
			ren v34 p1_elec_215
			ren v35 p1_water_215
			keep area code year file p1*_215
			destring p1*_215, replace
			replace area = trim(area)
			recast str area
			append using `c4'
			save `c4', replace
		}
		else if v31[1]== "mean(all2v~215)" {	 //c5 
			drop if v31== "mean(all2v~215)"
			ren v1 area
			ren v31 all2vul_215 
			ren v32 all3vul_215
			ren v33 all4vul_215
			ren v34 all5vul_215
			ren v35 all6vul_215
			keep area code year file all*vul*
			destring all*vul*, replace
			replace area = trim(area)
			recast str area
			append using `c5'
			save `c5', replace
		}
		//365
		else if v31[1]== "mean(poor365~n)" {	 //c6 
			drop if v31== "mean(poor365~n)"
			ren v1 area			
			ren v31 poor365_ln
			ren v32 dim6_365
			ren v33 multvul_365
			keep area code year file poor365_ln dim6_365 multvul_365
			destring poor365_ln dim6_365 multvul_365, replace
			
			replace area = trim(area)
			recast str area
			append using `c6'
			save `c6', replace
		}
		else if v31[1]== "mean(p1_ed~365)" {	 //c7	
			drop if v31== "mean(p1_ed~365)"
			ren v1 area						
			ren v31 p1_edu_365
			ren v32 p1_sp_365
			ren v33 p1_fin_365
			ren v34 p1_elec_365
			ren v35 p1_water_365
			keep area code year file p1*_365
			destring p1*_365, replace
			replace area = trim(area)
			recast str area
			append using `c7'
			save `c7', replace
		}
		else if v31[1]== "mean(all2v~365)" {	 //c8
			drop if v31== "mean(all2v~365)"
			ren v1 area
			ren v31 all2vul_365
			ren v32 all3vul_365
			ren v33 all4vul_365
			ren v34 all5vul_365
			ren v35 all6vul_365
			keep area code year file all*vul*
			destring all*vul*, replace
			replace area = trim(area)
			recast str area
			append using `c8'
			save `c8', replace
		}
		//685
		else if v31[1]== "mean(poor685~n)" {	 //c9
			drop if v31== "mean(poor685~n)"
			ren v1 area			
			ren v31 poor685_ln
			ren v32 dim6_685
			ren v33 multvul_685
			keep area code year file poor685_ln dim6_685 multvul_685
			destring poor685_ln dim6_685 multvul_685, replace
			
			replace area = trim(area)
			recast str area
			append using `c9'
			save `c9', replace
		}
		else if v31[1]== "mean(p1_ed~685)" {	 //c10
			drop if v31== "mean(p1_ed~685)"
			ren v1 area						
			ren v31 p1_edu_685
			ren v32 p1_sp_685
			ren v33 p1_fin_685
			ren v34 p1_elec_685
			ren v35 p1_water_685
			keep area code year file p1*_685
			destring p1*_685, replace
			replace area = trim(area)
			recast str area
			append using `c10'
			save `c10', replace
		}
		else { //c11 mean(all2v~685)		
			drop if v31== "mean(all2v~685)"
			ren v1 area
			ren v31 all2vul_685
			ren v32 all3vul_685
			ren v33 all4vul_685
			ren v34 all5vul_685
			ren v35 all6vul_685
			keep area code year file all*vul*
			destring all*vul*, replace
			replace area = trim(area)
			recast str area
			append using `c11'
			save `c11', replace
		}		
	} // gr listb
} //lista

use `c1', clear
forv i=2(1)11 {
	merge 1:1 code year file area using `c`i''
	drop _merge	
}

drop if area=="reg_rural"
ren area sample
gen level = "_all_"
ren welfare mean_ln
gen lineupyear = $lnyear
gen baseyear = year 
order code year file /*survname*/ level sample baseyear lineupyear mean_ln poor215_ln poor365_ln poor685_ln dep_* multvul_* all*vul* p1* dim6* _count h

destring year, replace
merge m:1 code year using "${upath2}\03.intermediate\Lineuplist\LISSY_ln_list_${lnyear}", keepus(survname survey_coverage datatype comparability)
keep if _merge==3
drop _merge

sort code year sample
ren p1* pov1*
order code year file survname survey_coverage datatype comparability level sample baseyear lineupyear mean_ln poor215_ln poor365_ln poor685_ln dep_* multvul_* all*vul* pov1* dim6* _count h
destring baseyear, replace
drop file  
char define _dta[date] "`date' `time'"
char define _dta[user] "`user'"
compress

saveold "${upath2}\03.intermediate\Sim\\${lnyear}\\${rnd}_LIS_nat_vul_${lnyear}", replace

