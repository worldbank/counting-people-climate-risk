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

//GMD vul

clear all
set more off
set matsize 5000	
mat drop _all
set varabbrev off

//setting
global rnd AM24
global sim 100
*global upath2 c:\Users\WB327173\OneDrive - WBG\Downloads\ECA\Global\Climate change and poverty\Vulnerable to poverty and climate 2.0\
global reposource "${upath2}\02.input"
global repotxt repo(use ${rnd}all) reporoot(${reposource})
global lnyear 2021
global circa 3
global plinelist 215 365 685

cap log close
log using "${upath2}\03.intermediate\Sim\\${lnyear}\\GMD_log_${lnyear}.txt", text replace
local date: di %tdMon-DD-CCYY date("$S_DATE", "DMY")
local user = "`c(username)'"
local fdataall_ln Vul_dataall_${lnyear}_`date'

tempfile dataall dataall_ln data4 data5 ctry1 ctry1ln
save "${upath2}\03.intermediate\Sim\Vintages\\`fdataall_ln'", replace emptyok

//GMD todo list
use "${upath2}\02.input\\${lnyear}\GMD_list_${lnyear}", clear
replace todo = 0 if todo==.

//update manually
replace level = "subnatid1" if level == "subnatid" & code=="KGZ" & surv_year==2010
replace level = "subnatid" if level == "" & code=="UGA" & surv_year==2009

//Doing outside GMD: India, CHN, and LIS countries
drop if (code=="CHN"|code=="IND") & ${lnyear}==2021
drop if (code=="CHN") & ${lnyear}==2010
drop if strpos(survname,"-LIS")>0
drop if mod=="HIST"
drop if code=="SYR"
replace ct_urban = 0 if code=="SYC" & surv_year==2018
//add flag missing =4
foreach var of varlist elec_flag water_flag sp_flag findex_flag edu_flag {
	replace `var'= 4 if `var'==.
}

ren level lvlvar 
replace lvlvar = "" if lvlvar=="national"
local allobs = _N
tempfile gmdlist
save `gmdlist', replace

qui forv j=1(1)`allobs' {
*qui forv i=1(1)1 {
	use `gmdlist', clear
	foreach lc in code surv_year survname mod lvlvar elec_flag water_flag sp_flag findex_flag edu_flag ct_urban todo {
		local `lc' = `lc'[`j']
	}
		
	//Load lineup poverty/pop at national level
	foreach num of numlist ${plinelist}  {
		use "${upath2}\03.intermediate\PIPinput\PIP_${lnyear}_`num'.dta", clear	
		keep if country_code=="`code'"
		count
		local pcnpov`num'
		local pcnpop
		if r(N)>0 {
			local pcnpov`num' = headcount[1]
			local pcnpop = population[1]
		}
	}
	
	//Get values for fusion ASPIRE FINDEX, etc when flags==3
	****************************************************    
	//ASPIRE 
	if `sp_flag'==3 {
		use "${upath2}\02.input\\${lnyear}\ASPIRE_data_${lnyear}.dta", clear
		keep if code=="`code'"
		local aspire_sp
		count
		if r(N)>0 {
			local type_aspire = type[1]
			if "`type_aspire'"=="Quintile" {
				local aspire_sp	= 1
				forv i=1(1)5 {
					local _pop_All_SPL_q`i' = _pop_All_SPL_q`i'[1]
				}
			}
			else { //type_aspire == National
				local _pop_All_SPL = _pop_All_SPL[1]
				local aspire_sp	= 1
			}
		} //rn>0
		else {
			local aspire_sp = 0
		}
	} //sp_flag
	
	****************************************************	
	//FINDEX data (no account, which is dep_fin)
	if `findex_flag'==3 {
		use "${upath2}\02.input\\${lnyear}\findex_${lnyear}_quintiles.dta", clear
		keep if code=="`code'"
		local findex
		count
		if r(N)>0 {
			local type_findex = type[1]
			local findex	= 1
			if `ct_urban'==0 local type_findex "Total"
			if "`type_findex'"=="Urb_rur" { //urban-rural quintiles
				local findex	= 1
				forv i=1(1)5 {
					foreach nm in urban rural {
						local no_accountq`i'`nm' = no_accountq`i'`nm'[1]
					}
				}
			}
			else { //total quintiles
				local findex	= 1
				forv i=1(1)5 {
					local no_accountq`i'total = no_accountq`i'total[1]
				}
			} //types			
		}
		else { //rn>0
			local findex = 0
		}
	} //findex_flag
	
	****************************************************
	//JMP data
	if `water_flag'==3 {
		use "${upath2}\02.input\\${lnyear}\JMP_cov_${lnyear}.dta", clear
		keep if code=="`code'"
		local jmp
		count
		if r(N)>0 {
			local type_jmp = type[1]
			local jmp	= 1
			if `ct_urban'==0 local type_jmp "Total"				
			if "`type_jmp'"=="Urb_rur" { //urban-rural only	
				local w_imp_urban = w_imp_urban[1]
				local w_imp_rural = w_imp_rural[1]
			}
			else { //total 
				local w_imp_total = w_imp_total[1]
			} //types
		}
		else { //rn>0
			local jmp = 0
		}
	} //water_flag
	
	****************************************************
	//Electricity GED
	if `elec_flag'==3 {
		use "${upath2}\02.input\\${lnyear}\GED_cov_${lnyear}.dta", clear
		keep if code=="`code'"
		local ged
		count
		if r(N)>0 {
			local type_ged = type[1]
			local ged	= 1
			if `ct_urban'==0 local type_ged "Total"				
			if "`type_ged'"=="Urb_rur" { //urban-rural only	
				local ged_urban = ged_urban[1]
				local ged_rural = ged_rural[1]
			}
			else { //total quintiles
				local ged_total = ged_total[1]
			} //types						
		}
		else { //rn>0
			local ged = 0
		}
	} //elec_flag
	
	****************************************************
	//UNESCO
	if `edu_flag'==3 {
		use "${upath2}\02.input\\${lnyear}\UNESCO_cov_${lnyear}.dta", clear
		keep if code=="`code'"
		local unesco
		count
		if r(N)>0 {
			local type_unesco = type[1]
			local unesco	= 1
			if `ct_urban'==0 local type_unesco "Total"				
			if "`type_unesco'"=="Urb_rur" { //urban-rural only	
				local unesco_urban = unesco_urban[1]
				local unesco_rural = unesco_rural[1]
			}
			else { //total quintiles
				local unesco_total = unesco_total[1]
			} //types
		}
		else { //rn>0
			local unesco = 0
		}
	}
	
	//microdata
	cap dlw, country(`code') year(`surv_year') type(gmd) mod(`mod') surveyid(`survname') files $repotxt
	if _rc==0 {	
		cap ren sim simsur
		local baseyear = `surv_year'
		local year = `surv_year'
		local lineupyear = $lnyear
		gen _all_ = "All sample"	
		noi dis "`j' - Working on `code'-`surv_year'-`survname'-`mod'"
		
		if "`mod'"=="GPWG" local wgt weight
		else local wgt weight_p
		
		//Prep subnational level
		if ("`lvlvar'"=="") local oklist _all_
		else {		
			cap confirm numeric variable `lvlvar'
			if _rc==0 {
				tempvar xvar
				cap decode `lvlvar', gen(`xvar')
				if _rc~=0 tostring `lvlvar', gen(`xvar')
				cap drop `lvlvar'
				rename `xvar' `lvlvar'		
			}			
			replace `lvlvar' = "MISSING" if `lvlvar'==""
			replace `lvlvar' = ustrtrim(`lvlvar')
			local oklist `lvlvar'	
		}
				
		//adjustment for country specific fix subnational
		qui {
			if "`code'"=="PHL" & "`survname'"=="FIES" & (`year'==2018) { //ok
				if "`lvlvar'"=="subnatid2" {				
					replace subnatid2="Basilan" if subnatid2=="7-Basilan" | subnatid2=="97-Isabela City"
					replace subnatid2="North Cotabato" if subnatid2=="47-Cotabato"
					replace subnatid2="Davao Del Sur" if subnatid2=="24-Davao de Sur" | subnatid2=="86-Davao Occidental"
					replace subnatid2="Maguindanao" if subnatid2=="38-Maguindanao" | subnatid2=="98-Cotabato City"
					replace subnatid2="Metropolitan Manila" if subnatid2=="39-Manila" | subnatid2=="74-NCR-2nd Dist." | subnatid2=="75-NCR-3rd Dist." | subnatid2=="76-NCR-4th Dist."
					local oklist subnatid2
				}
			}
			
			if "`code'"=="PHL" & "`survname'"=="FIES" & `year'==2021 { //ok
				if "`lvlvar'"=="subnatid2" {				
					replace subnatid2="Basilan" if subnatid2=="7-Basilan" | subnatid2=="97-Isabela City"
					replace subnatid2="North Cotabato" if subnatid2=="47-Cotabato"
					replace subnatid2="Davao Del Sur" if subnatid2=="24-Davao de Sur" | subnatid2=="86-Davao Occidental"
					replace subnatid2="Maguindanao" if subnatid2=="38-Maguindanao" | subnatid2=="98-Cotabato City"
					replace subnatid2="Metropolitan Manila" if subnatid2=="39-Manila" | subnatid2=="74-NCR-2nd Distr." | subnatid2=="75-NCR-3rd Distr." | subnatid2=="76-NCR-4th Distr."		
					local oklist subnatid2
				}
			}
			
			if "`code'"=="ALB" & "`survname'"=="LSMS" & `year'==2012 { //ok
				decode strata, gen(subnatid)
				replace subnatid = subinstr(subnatid, "_Rural","",.)
				replace subnatid = subinstr(subnatid, "_Urban","",.)
				local oklist subnatid
			}
			
			if "`code'"=="BGD" & "`survname'"=="HIES" & (`year'==2016|`year'==2022) { //ok
				replace subnatid = "40 - Khulna" if subnatid=="45 - Mymensingh"	| subnatid=="45-Mymensingh"|subnatid=="40-Khulna"
				local oklist subnatid
			}
			
			if "`code'"=="GEO" & "`survname'"=="HIS" { //ok
				if `year'>=2019 & `year'<=2021 {
					replace subnatid="10 - Imereti, Racha-Lechkhumi and Kvemo Svan" if subnatid=="10 - Imereti" | subnatidsurvey=="13 - Racha-Lechkhumi and Kvemo Svaneti"
				}
				if `year'>=2002 & `year'<=2009 {
					replace subnatid="10 - Imereti, Racha-Lechkhumi and Kvemo Svan" if subnatid=="10-Imereti"
					replace subnatid="7 - Adjara A.R." if subnatid=="7-Ajara"
					replace subnatid="9 - Samegrelo-Zemo Svaneti" if subnatid=="9-Samegrelo"	
				}			
			}
			
			if "`code'"=="IDN" & "`survname'"=="SUSENAS" { //ok
				if (`year'>=2010 & `year'<=2023) {
					replace `lvlvar' = "64-65-North and East Kalimantan" if `lvlvar'=="64-East Kalimantan" | `lvlvar'=="65-North Kalimantan"	
				}
								
				if `year'==2005 {
					replace `lvlvar' = "21-Riau Islands" if `lvlvar'=="21-Riau Island"
					replace `lvlvar' = "64-65-North and East Kalimantan" if `lvlvar'=="64-East Kalimantan" | `lvlvar'=="65-North Kalimantan"
				}
			}
			
			if "`code'"=="MNE" & "`survname'"=="SILC-C" & (`year'==2016 | `year'==2017) { //ok
				gen subnatid1=""
				replace subnatid1="1 – North" if subnatid=="1 – North urban" | subnatid=="5 – North rural"
				replace subnatid1="2 – Center" if subnatid=="2 – Center urban" | subnatid=="6 – Center rural"
				replace subnatid1="3 – South" if subnatid=="3 – South urban" | subnatid=="7 – South rural"
				replace subnatid1="4 – Podgorica" if subnatid=="4 – Podgorica urban" | subnatid=="8 – Podgorica rural"
				
				local oklist subnatid1
			}
			
			if "`code'"=="DJI" & "`survname'"=="EDAM" & `year'==2017 {	//ok		
				gen subnatid1=subnatid
				replace subnatid1="10 - Djibouti" if subnatid=="11 - Djibouti-ville, 1er arrondissement"
				replace subnatid1="10 - Djibouti" if subnatid=="12 - Djibouti-ville, 2eme arrondissement"
				replace subnatid1="10 - Djibouti" if subnatid=="13 - Djibouti-ville, 3eme arrondissement"
				replace subnatid1="10 - Djibouti" if subnatid=="14 - Djibouti-ville, 4eme arrondissement"
				replace subnatid1="10 - Djibouti" if subnatid=="15 - Djibouti-ville, 5eme arrondissement"

				local oklist subnatid1
			}
			if "`code'"=="STP" { //ok
				if `year'==2010 {                                          
					replace `lvlvar' = "1 - São Tomé" if `lvlvar'=="1 - Nord" | `lvlvar'=="2 - Centre" | `lvlvar'=="3 - Sud" 
					replace `lvlvar' = "2 - Principé" if `lvlvar'=="4 - Principé"	
				}
				if  `year'==2000 {                                          
					replace `lvlvar' = "1 - São Tomé" if `lvlvar'=="1 – Nord" | `lvlvar'=="2 – Centre" | `lvlvar'=="3 – Sud" 
					replace `lvlvar' = "2 - Principé" if `lvlvar'=="4 – Principé"	
				}
				if `year'==2017 {
					replace `lvlvar' = "1 - São Tomé" if `lvlvar'=="1 - Lobata"|`lvlvar'=="2 - Lembá"|`lvlvar'=="3 - Mezochi"|`lvlvar'=="4 - Agua Grande"|`lvlvar'=="5 - Cantagalo"|`lvlvar'=="6 - Caué"
					replace `lvlvar' = "2 - Principé" if `lvlvar'=="7 - Príncipe"
				}	
			}
			
			if "`code'"=="EGY" & "`survname'"=="HIECS" & (`year'==2010 | `year'==2012) {
				replace subnatid="1-Metropolitan" if subnatid=="1-Metropolitan"|subnatid=="1 - Metropolitan"
				replace subnatid="2-Lower" if subnatid=="2-Lower Urban"|subnatid=="3-Lower Rural"
				replace subnatid="2-Lower" if subnatid=="2 - Lower Urban"|subnatid=="3 - Lower Rural"
				replace subnatid="4-Upper" if subnatid=="4-Upper Urban"|subnatid=="5-Upper Rural"
				replace subnatid="4-Upper" if subnatid=="4 - Upper Urban"|subnatid=="5 - Upper Rural"
				replace subnatid="6-Borders" if subnatid=="6-Borders Urban"|subnatid=="7-Borders Rural"
				replace subnatid="6-Borders" if subnatid=="6 - Borders Urban"|subnatid=="7 - Borders Rural"
				local oklist subnatid
			}
			if "`code'"=="EGY" & "`survname'"=="HIECS" & (`year'==2017 | `year'==2015) {
				if "`lvlvar'"=="subnatid1" {								
					replace subnatid1="1-Metropolitan" if subnatid1=="1-Metropolitan"
					replace subnatid1="2-Lower" if subnatid1=="2-Lower Urban"|subnatid1=="3-Lower Rural"
					replace subnatid1="4-Upper" if subnatid1=="4-Upper Urban"|subnatid1=="5-Upper Rural"
					replace subnatid1="6-Borders" if subnatid1=="6-Borders Urban"|subnatid1=="7-Borders Rural"
					local oklist subnatid1
				}
				if "`lvlvar'"=="subnatid" local oklist subnatid
			}
			
			if "`code'"=="EGY" & "`survname'"=="HIECS" & (`year'==2019) {
				if "`lvlvar'"=="subnatid" {								
					replace subnatid="1-Metropolitan" if subnatid=="1-Metropolitan"
					replace subnatid="2-Lower" if subnatid=="2-Lower Urban"|subnatid=="3-Lower Rural"
					replace subnatid="4-Upper" if subnatid=="4-Upper Urban"|subnatid=="5-Upper Rural"
					replace subnatid="6-Borders" if subnatid=="6-Borders Urban"|subnatid=="7-Borders Rural"
					local oklist subnatid
				}	
			}
			
			if "`code'"=="FIN" & "`survname'"=="EU-SILC" & (`year'>=2008 & `year'<=2010)  {
				replace subnatid="4-FI1C" if subnatid=="1-FI18"
				local oklist subnatid
			}
			
			if "`code'"=="CIV" & "`survname'"=="ENV" & `year'==2015  {
				*decode gaul_adm1, gen(gaul_adm1_str)
				*local oklist gaul_adm1_str
			}
			
			if "`code'"=="CIV" & "`survname'"=="EHCVM" & (`year'==2018| `year'==2021) {			
				replace subnatid = trim(proper(lower( subnatid)))
				gen gaul_adm1_str = ""
				replace gaul_adm1_str="Folon" if subnatid=="10 - Kabadougou"
				replace gaul_adm1_str="Folon" if subnatid=="24 - Folon"
				replace gaul_adm1_str="Tchologo" if subnatid=="20 - Bagoue"
				replace gaul_adm1_str="Tchologo" if subnatid=="3 - Poro"
				replace gaul_adm1_str="Tchologo" if subnatid=="32 - Tchologo"
				replace gaul_adm1_str="Hambol" if subnatid=="28 - Hambol"
				replace gaul_adm1_str="Hambol" if subnatid=="4 - Gbeke"
				replace gaul_adm1_str="Bounkani" if subnatid=="23 - Bounkani"
				replace gaul_adm1_str="Bounkani" if subnatid=="8 - Gontougo"
				replace gaul_adm1_str="Sud-Comoe" if subnatid=="13 - Sud-Comoe"
				replace gaul_adm1_str="Sud-Comoe" if subnatid=="5 - Indenie-Djuablin"
				replace gaul_adm1_str="District autonome D'abidjan" if subnatid=="1 - Autonome D'Abidjan"
				replace gaul_adm1_str="District autonome de Yamoussou" if subnatid=="7 - Yamoussoukro"
				replace gaul_adm1_str="Goh" if subnatid=="15 - LÔH-Djiboua"
				replace gaul_adm1_str="Goh" if subnatid=="17 - GÔH"
				replace gaul_adm1_str="Moronou" if subnatid=="11 - N'Zi"
				replace gaul_adm1_str="Moronou" if subnatid=="21 - Belier"
				replace gaul_adm1_str="Moronou" if subnatid=="29 - Iffou"
				replace gaul_adm1_str="Moronou" if subnatid=="33 - Moronou"
				replace gaul_adm1_str="La Me" if subnatid=="16 - Agneby-Tiassa"
				replace gaul_adm1_str="La Me" if subnatid=="26 - Grands-Ponts"
				replace gaul_adm1_str="La Me" if subnatid=="30 - La Me"
				replace gaul_adm1_str="Guemon" if subnatid=="18 - Cavally"
				replace gaul_adm1_str="Guemon" if subnatid=="27 - Guemon"
				replace gaul_adm1_str="Guemon" if subnatid=="6 - Tonkpi"
				replace gaul_adm1_str="Marahoue" if subnatid=="12 - Marahoue"
				replace gaul_adm1_str="Marahoue" if subnatid=="2 - Haut-Sassandra"
				replace gaul_adm1_str="Bere" if subnatid=="14 - Worodougou"
				replace gaul_adm1_str="Bere" if subnatid=="19 - Bafing"
				replace gaul_adm1_str="Bere" if subnatid=="22 - Bere"
				replace gaul_adm1_str="Nawa" if subnatid=="25 - GbÔKle"
				replace gaul_adm1_str="Nawa" if subnatid=="31 - Nawa"
				replace gaul_adm1_str="Nawa" if subnatid=="9 - San-Pedro"

				local oklist gaul_adm1_str
			}
			
			if "`code'"=="COM" & "`survname'"=="EESIC" & `year'==2013  { //ok			
				replace subnatid="1 - Moroni" if subnatid=="2 - Reste Ngazidja"	
				local oklist subnatid
			}
			/*
			if "`file'"=="SSA_GMB_2015_IHS_LN2018_IND.dta" {
				replace subnatid="6 – Kuntaur" if subnatid=="7 – Janjanbureh"
			}
			*/
			
			if "`code'"=="NAM" & "`survname'"=="NHIES" & `year'==2015 {	//ok	
				replace subnatid="4-kavango east" if subnatid=="5-kavango west"
				local oklist subnatid
			}
			
			if "`code'"=="SLE" & "`survname'"=="SLIHS" & `year'==2018 {	 //ok		
				replace subnatid2="51-Western Area" if subnatid2=="51-Western Area Rural" | subnatid2=="52-Western Area Urban"		
				replace subnatid2="21–Bombali/32–Karene" if subnatid2=="21-Bombali" | subnatid2=="32-Karene"
				replace subnatid2="22–Falaba/23–Koinadugu" if subnatid2=="22-Falaba" | subnatid2=="23-Koinadugu"	
				local oklist subnatid2
			}
			
			if "`code'"=="SLE" & "`survname'"=="SLIHS" & `year'==2011 { //ok
				replace subnatid2="51-Western Area" if subnatid2=="41 - Western other" | subnatid2=="42 - Western urban (Freetown)"		
				local oklist subnatid2
			}
			
			if "`code'"=="SLE" & "`survname'"=="SLIHS" & `year'==2003 { //ok
				replace subnatid="51-Western Area" if subnatid=="41 - Western other" | subnatid=="42 - Western urban"		
				local oklist subnatid
			}
			/*
			if "`file'"=="SSA_GAB_2017_EGEP_LN2018_IND.dta" {	//check			
				/* ALREADY DONE, strata is from SSAPOV module P
				gen subnatid = strata
				replace subnatid = "11-Ouest" if strata=="10-Reste Ouest Urbain" | strata=="11-Ouest Rural"
				replace subnatid = "4-Nord" if strata=="4-Nord-Urbain" | strata=="5-Nord-Rural"
				replace subnatid = "6-Sud" if strata=="6-Sud-Urbain" | strata=="7-Sud-Rural"
				replace subnatid = "9-Est" if strata=="8-Reste Est Urbain" | strata=="9-Est Rural"
				*/
			}
			
			if "`file'"=="EAP_WSM_2008_HIES_LN2018_IND.dta" {	
				replace subnatid="Upolu" if subnatid=="1-Apia"
				replace subnatid="Upolu" if subnatid=="2-NWU"
				replace subnatid="Upolu" if subnatid=="3-RoU"
			}
			*/
			/*
			if "`code'"=="TLS" & "`survname'"=="TLSLS" & `year'==2014 { //ok		
				gen str subnatidx = ""
				replace subnatidx = "1-Aileu,Dili and Emera" if subnatid1=="01-Aileu"
				replace subnatidx = "1-Aileu,Dili and Emera" if subnatid1=="02-Dili"
				replace subnatidx = "1-Aileu,Dili and Emera" if subnatid1=="03-Ermera"
				replace subnatidx = "2-Ainaro, Manatutao and Manufahi" if subnatid1=="04-Ainaro"
				replace subnatidx = "2-Ainaro, Manatutao and Manufahi" if subnatid1=="06-Manufahi"
				replace subnatidx = "2-Ainaro, Manatutao and Manufahi" if subnatid1=="05-Manatuto"
				replace subnatidx = "5-Oecussi" if subnatid1=="13-Oecussi"
				replace subnatidx = "4-Bobonaro, Cova Lima and Liquica" if subnatid1=="10-Bobonaro"
				replace subnatidx = "4-Bobonaro, Cova Lima and Liquica" if subnatid1=="11-Covalima"
				replace subnatidx = "4-Bobonaro, Cova Lima and Liquica" if subnatid1=="12-Liquica"
				replace subnatidx = "3-Baucau,Lautem and Viqueque" if subnatid1=="09-Viqueque"
				replace subnatidx = "3-Baucau,Lautem and Viqueque" if subnatid1=="08-Lautem"
				replace subnatidx = "3-Baucau,Lautem and Viqueque" if subnatid1=="07-Baucau"
				local oklist subnatidx
			}
			*/	
			if "`code'"=="MWI" { //ok		
				if `year'>=2010 {
					replace `lvlvar'="105/107 Mzimba" if `lvlvar'=="105 - Mzimba" | `lvlvar'=="107 - Mzuzu City"|`lvlvar'=="107 – Mzuzu City"	
					replace `lvlvar'="305/315 Blantyre" if `lvlvar'=="315 - Blantyre City" | `lvlvar'=="305 - Blantyre"| `lvlvar'=="315 – Blantyre City"
					replace `lvlvar'="206/210 Lilongwe" if `lvlvar'=="210 - Lilongwe City" | `lvlvar'=="206 - Lilongwe"| `lvlvar'=="210 – Lilongwe City"
					replace `lvlvar'="303/314 Zomba" if `lvlvar'=="303 - Zomba" | `lvlvar'=="314 - Zomba City"
					replace `lvlvar'="303/314 Zomba" if `lvlvar'=="303 – Zomba Non-City" | `lvlvar'=="314 – Zomba City"
				}
				if `year'==1997 {
					replace `lvlvar'="105/107 Mzimba" if `lvlvar'=="130 – Mzimba" | `lvlvar'=="131 – Mzuzu City"
					replace `lvlvar'="305/315 Blantyre" if `lvlvar'=="304 – Blantyre Rural" | `lvlvar'=="305 – Blantyre City"
					replace `lvlvar'="206/210 Lilongwe" if `lvlvar'=="223 – Lilongwe Rural" | `lvlvar'=="224 – Lilongwe City"
					replace `lvlvar'="303/314 Zomba" if `lvlvar'=="306 – Zomba Rural" | `lvlvar'=="307 – Zomba City"				
				}
			}
			
			if "`code'"=="TCD" & "`survname'"=="EHCVM" & `year'==2018 {	 //ok	
				replace subnatid="3-Borkou-Ennedi-Tibesti" if subnatid=="2 - Borkou" | subnatid=="20 - Ennedi Ouest"
			}
			
			/*
			if "`file'"=="LAC_BOL_2018_EH_LN2018_IND.dta" {	
				replace subnatid2 = trim(subnatid2)
				replace subnatid2="8/9 Beni and Pando" if subnatid2=="8 - Beni" | subnatid2=="9 - Pando"		
			}
			*/
			
			if "`code'"=="DOM" & ("`survname'"=="ECNFT-Q03"|"`survname'"=="ENFT") { //ok			
				replace `lvlvar'= trim(`lvlvar')
				replace `lvlvar'="2 - Norte o Cibao" if `lvlvar'=="2 - Cibao Norte" | `lvlvar'=="3 - Cibao Sur"	| `lvlvar'=="4 - Cibao Nordeste" | `lvlvar'=="5 - Cibao Noroeste"	
				replace `lvlvar'="3 - Sur" if `lvlvar'=="6 - Valdesia" | `lvlvar'=="7 - El Valle"	| `lvlvar'=="8 - Enriquillo" 
				replace `lvlvar'="4 - Este" if `lvlvar'=="9 - Higuamo" | `lvlvar'=="10 - Yuma" 
			}
			
			if "`code'"=="NER" & "`survname'"=="EHCVM" & `year'==2021 {	//ok	
				replace subnatid="1 - Agadez" if subnatid=="1 - gadez" 
			}
			
			if "`code'"=="BRA" {	//ok	
				replace subnatid2="43 - Rio Grande do Sul" if subnatid2== "43 - Rio Grande do Norte"
			}
			
			if "`code'"=="BWA" {	//ok	
				replace subnatid="3 – Other Towns" if subnatid== "3 - Other cities & towns"
				replace subnatid="4 – South East" if subnatid== "4 - Rural South-East"
				replace subnatid="5 – North East" if subnatid== "5 - Rural North-East"
				replace subnatid="6 – North West" if subnatid== "6 - Rural North-West"
				replace subnatid="7 – South West" if subnatid== "7 - Rural South-West"
			}
			
			if "`code'"=="CAF" {	//ok	
				replace subnatid2="3 - Yadé" if subnatid2== "3 - Yade"
			}
			
			if "`code'"=="BFA" {	//ok	
				replace subnatid="1 - Boucle du Mouhoun" if subnatid== "1 - Boucle du Mouhoum"
			}
			
			if "`code'"=="CMR" & "`survname'"=="ECAM-V" & `year'==2021 {	//ok
				egen sample3 = sieve(subnatid), keep(a)
				gen sample3UP = upper(sample3)		
				replace subnatid="10 -Sud-Oues" if subnatid== "11 - sud-ouest"
				replace subnatid="2 - Centre" if sample3UP== "YAOUND"
				replace subnatid="6 - Littoral" if subnatid== "3 - douala"
				drop  sample3 sample3UP
			}
			
			if "`code'"=="IRN" {
				replace `lvlvar' = "10 - Isfahan" if `lvlvar'=="11 - Esfahan"
				replace `lvlvar' = "11 - Sistan" if `lvlvar'=="12 - SistanBalouchestan"
				replace `lvlvar' = "12 - Kurdestan" if `lvlvar'=="13 - Kordestan"
				replace `lvlvar' = "13 - Hamadan" if `lvlvar'=="14 - Hamedan"
				replace `lvlvar' = "14 - Bakhtiari" if `lvlvar'=="15 - CharmahalBakhtiari"
				replace `lvlvar' = "17 - Kohkiloyeh" if `lvlvar'=="18 - KohkilouyeBoyerahamad"
				replace `lvlvar' = "18 - Bushehr" if `lvlvar'=="19 - Boushehr"
				replace `lvlvar' = "28 - N. Khorasan" if `lvlvar'=="29 - KhorasanShomali"
				replace `lvlvar' = "S. Khorasan" if `lvlvar'=="30 - KhorasanJonoubi"
				replace `lvlvar' = "3 - E.Azarbaijan" if `lvlvar'=="4 - AzarbaijanSharghi"
				replace `lvlvar' = "4 - W.Azarbaijan" if `lvlvar'=="5 - AzarbaijanGharbi"
				replace `lvlvar' = "6 - Khuzestan" if `lvlvar'=="7 - Kouzestan"
			}
			
			if "`code'"=="KAZ" {
				replace `lvlvar' = "51 - South_Kaz" if `lvlvar'=="61 - Turkistan"
			}
			
			if "`code'"=="KGZ" {
				replace `lvlvar' = "2-Issyk-kul" if `lvlvar'=="2-Issyk-ku"
				replace `lvlvar' = "3-Jalal-Abad" if `lvlvar'=="3-Jalalaba"
			}
			
			if "`code'"=="LAO" {
				replace `lvlvar' = "18-Xaysomboon" if `lvlvar'=="18-Xaisomboun"
			}
			
			if "`code'"=="MAR" {	 //old shapefile for 2000 and 2006
				/*
				replace `lvlvar' = "" if `lvlvar'=="1 - Regions sahariennes"
				replace `lvlvar' = "" if `lvlvar'=="10 - Tadla-Azilal"
				replace `lvlvar' = "" if `lvlvar'=="11 - Meknes-Tafilalet"
				replace `lvlvar' = "" if `lvlvar'=="12 - Fes-Boulemane-Taounate"
				replace `lvlvar' = "" if `lvlvar'=="13 - Taza-Hoceima"
				replace `lvlvar' = "1 - Tanger-Tetouan-Al Hoceima" if `lvlvar'=="14 - Tanger-Tetouan"
				replace `lvlvar' = "9 - Souss-Massa" if `lvlvar'=="2 - Souss- Massa-Draa"
				replace `lvlvar' = "5 - Beni Mellal-Khenifra" if `lvlvar'=="3 - Gharb-Chrarda-Beni Hssen"
				replace `lvlvar' = "" if `lvlvar'=="4 - Chaouia-Ouardigha"
				replace `lvlvar' = "7 - Marrakech-Safi" if `lvlvar'=="5 - Marrakech-Tensift-Haouz"
				replace `lvlvar' = "2 - Oriental" if `lvlvar'=="6 - Oriental"
				replace `lvlvar' = "6 - Grand Casablanca" if `lvlvar'=="7 - Grand Casablanca"
				replace `lvlvar' = "4 - Rabat-Salé-Kenitra" if `lvlvar'=="8 -Rabat-Sale-Zemmour-Zaer"
				replace `lvlvar' = "" if `lvlvar'=="9 - Doukkala-Abda"
				*/
			}

			if "`code'"=="MOZ" & "`survname'"=="IOF" & `year'==2022 {	//oklist
				replace `lvlvar' = "Maputo Cidade" if `lvlvar'=="Cidade de Maputo"
			}

			if "`code'"=="MLI" & "`survname'"=="EHCVM" & `year'==2021 {	//ok
				egen sample3 = sieve(subnatid), keep(a)
				gen sample3UP = upper(sample3)					
				replace subnatid="4 - Sgou" if sample3UP== "SEGOU"			
				drop  sample3 sample3UP
			}
			
			if "`code'"=="MMR" & `year'==2017 {	 			
				replace `lvlvar' = "14-Ayeyawaddy" if trim(`lvlvar')=="14-Ayeyawaddy"
				replace `lvlvar' = "2-Kayar" if trim(`lvlvar')=="2-Kayar"
				replace `lvlvar' = "6-Taninthayi" if trim(`lvlvar')=="6-Taninthayi"
			}
			
			if "`code'"=="MRT" {	 
				replace `lvlvar' = "1 - Hodh El Charghi" if `lvlvar'=="1 - Hodh charghy"
				replace `lvlvar' = "2 - Hodh El Gharbi" if `lvlvar'=="2 - Hodh Gharby"
				replace `lvlvar' = "11 - Tiris Zemmour" if `lvlvar'=="11 - Tirs-ezemour"
				replace `lvlvar' = "8 - Dakhlet Nouadhibou" if `lvlvar'=="8 - Dakhlett Nouadibou"			
			}
			
			if "`code'"=="PRY" & `year'>=2001 & `year'<=2017 {
				egen sample3 = sieve(`lvlvar'), keep(a)
				gen sample3UP = upper(sample3)							
				replace `lvlvar'="20 - Resto" if sample3UP== "CONCEPCION"
				replace `lvlvar'="20 - Resto" if sample3UP== "NEEMBUCU"
				replace `lvlvar'="20 - Resto" if sample3UP== "AMAMBAY"
				replace `lvlvar'="20 - Resto" if sample3UP== "CANINDEYU"
				replace `lvlvar'="20 - Resto" if sample3UP== "PRESIDENTEHAYES"
				replace `lvlvar'="20 - Resto" if sample3UP== "CORDILLERA"
				replace `lvlvar'="20 - Resto" if sample3UP== "GUAIRA"
				replace `lvlvar'="20 - Resto" if sample3UP== "MISIONES"
				replace `lvlvar'="20 - Resto" if sample3UP== "PARAGUARI"
				drop  sample3 sample3UP
			}
			
			if "`code'"=="POL" & "`survname'"=="HBS" {
				egen sample3 = sieve(`lvlvar'), keep(a)
				gen sample3UP = upper(sample3)					
				*gen subnatid2x = `lvlvar'
				replace `lvlvar'="1-PL2" if sample3UP=="MALOPOLSKIE"
				replace `lvlvar'="1-PL2" if sample3UP=="SLASKIE"
				replace `lvlvar'="2-PL4" if sample3UP=="WIELKOPOLSKIE"
				replace `lvlvar'="2-PL4" if sample3UP=="ZACHODNIOPOMORSKIE"
				replace `lvlvar'="2-PL4" if sample3UP=="LUBUSKIE"
				replace `lvlvar'="3-PL5" if sample3UP=="DOLNOSLASKIE"
				replace `lvlvar'="3-PL5" if sample3UP=="OPOLSKIE"
				replace `lvlvar'="4-PL6" if sample3UP=="KUJAWSKOPOMORSKIE"
				replace `lvlvar'="4-PL6" if sample3UP=="WARMINSKOMAZURSKIE"
				replace `lvlvar'="4-PL6" if sample3UP=="POMORSKIE"
				replace `lvlvar'="5-PL7" if sample3UP=="LODZKIE"
				replace `lvlvar'="5-PL7" if sample3UP=="SWIETOKRZYSKIE"
				replace `lvlvar'="6-PL8" if sample3UP=="LUBELSKIE"
				replace `lvlvar'="6-PL8" if sample3UP=="PODKARPACKIE"
				replace `lvlvar'="6-PL8" if sample3UP=="PODLASKIE"
				replace `lvlvar'="7-PL9" if sample3UP=="MAZOWIECKIE"
				local oklist `lvlvar' 			
			}
			
			if "`code'"=="POL" & "`survname'"=="EU-SILC" & `year'<=2017 {
				replace `lvlvar'="5-PL7" if `lvlvar'=="1-PL1"
				replace `lvlvar'="1-PL2" if `lvlvar'=="2-PL2"
				replace `lvlvar'="6-PL8" if `lvlvar'=="3-PL3"
				replace `lvlvar'="2-PL4" if `lvlvar'=="4-PL4"
				replace `lvlvar'="3-PL5" if `lvlvar'=="5-PL5"
				replace `lvlvar'="4-PL6" if `lvlvar'=="6-PL6"			
			}
			
			if "`code'"=="ROU"  {		
				replace `lvlvar'="2-RO2" if `lvlvar'=="1 - North-East" | `lvlvar'=="1-North-East"
				replace `lvlvar'="2-RO2" if `lvlvar'=="2 - South-East" | `lvlvar'=="2-South-East"
				replace `lvlvar'="3-RO3" if `lvlvar'=="3 - South"      | `lvlvar'=="3-South"
				replace `lvlvar'="4-RO4" if `lvlvar'=="4 - South-West" | `lvlvar'=="4-South-West"
				replace `lvlvar'="4-RO4" if `lvlvar'=="5 - West"       | `lvlvar'=="5-West"
				replace `lvlvar'="1-RO1" if `lvlvar'=="6 - North-West" | `lvlvar'=="6-North-West"
				replace `lvlvar'="1-RO1" if `lvlvar'=="7 - Centre"     | `lvlvar'=="7-Centre"
				replace `lvlvar'="3-RO3" if `lvlvar'=="8 - Bucharest-Ilfov" | `lvlvar'=="8-Bucharest-Ilfov"

				replace `lvlvar'="2-RO2" if `lvlvar'=="3-RO21"
				replace `lvlvar'="2-RO2" if `lvlvar'=="4-RO22"
				replace `lvlvar'="3-RO3" if `lvlvar'=="5-RO31"
				replace `lvlvar'="4-RO4" if `lvlvar'=="7-RO41"
				replace `lvlvar'="4-RO4" if `lvlvar'=="8-RO42"
				replace `lvlvar'="1-RO1" if `lvlvar'=="1-RO11"
				replace `lvlvar'="1-RO1" if `lvlvar'=="2-RO12"
				replace `lvlvar'="3-RO3" if `lvlvar'=="6-RO32"
			}
			
			if "`code'"=="THA"  {
				replace `lvlvar'="10-Bangkok" if `lvlvar'=="10"
				replace `lvlvar'="11-Samut Prakan" if `lvlvar'=="11"
				replace `lvlvar'="12-Nonthaburi" if `lvlvar'=="12"
				replace `lvlvar'="13-Pathum Thani" if `lvlvar'=="13"
				replace `lvlvar'="14-Phra Nakhon Si Ayu" if `lvlvar'=="14"
				replace `lvlvar'="15-Ang Thong" if `lvlvar'=="15"
				replace `lvlvar'="16-Lop Buri" if `lvlvar'=="16"
				replace `lvlvar'="17-Sing Buri" if `lvlvar'=="17"
				replace `lvlvar'="18-Chai Nat" if `lvlvar'=="18"
				replace `lvlvar'="19-Saraburi" if `lvlvar'=="19"
				replace `lvlvar'="20-Chon Buri" if `lvlvar'=="20"
				replace `lvlvar'="21-Rayong" if `lvlvar'=="21"
				replace `lvlvar'="22-Chanthaburi" if `lvlvar'=="22"
				replace `lvlvar'="23-Trat" if `lvlvar'=="23"
				replace `lvlvar'="24-Chachoengsao" if `lvlvar'=="24"
				replace `lvlvar'="25-Prachin Buri" if `lvlvar'=="25"
				replace `lvlvar'="26-Nakhon Nayok" if `lvlvar'=="26"
				replace `lvlvar'="27-Sa Kaeo" if `lvlvar'=="27"
				replace `lvlvar'="30-Nakhon Ratchasima" if `lvlvar'=="30"
				replace `lvlvar'="31-Buri Ram" if `lvlvar'=="31"
				replace `lvlvar'="32-Surin" if `lvlvar'=="32"
				replace `lvlvar'="33-Si Sa Ket" if `lvlvar'=="33"
				replace `lvlvar'="34-Ubon Ratchathani" if `lvlvar'=="34"
				replace `lvlvar'="35-Yasothon" if `lvlvar'=="35"
				replace `lvlvar'="36-Chaiyaphum" if `lvlvar'=="36"
				replace `lvlvar'="37-Am Nat Charoen" if `lvlvar'=="37"
				replace `lvlvar'="38-Bueng Kan" if `lvlvar'=="38"
				replace `lvlvar'="39-Nong Bua Lam Phu" if `lvlvar'=="39"
				replace `lvlvar'="40-Khon Kaen" if `lvlvar'=="40"
				replace `lvlvar'="41-Udon Thani" if `lvlvar'=="41"
				replace `lvlvar'="42-Loei" if `lvlvar'=="42"
				replace `lvlvar'="43-Nong Khai" if `lvlvar'=="43"
				replace `lvlvar'="44-Maha Sarakham" if `lvlvar'=="44"
				replace `lvlvar'="45-Roi Et" if `lvlvar'=="45"
				replace `lvlvar'="46-Kalasin" if `lvlvar'=="46"
				replace `lvlvar'="47-Sakon Nakhon" if `lvlvar'=="47"
				replace `lvlvar'="48-Nakhon Phanom" if `lvlvar'=="48"
				replace `lvlvar'="49-Mukdahan" if `lvlvar'=="49"
				replace `lvlvar'="50-Chiang Mai" if `lvlvar'=="50"
				replace `lvlvar'="51-Lamphun" if `lvlvar'=="51"
				replace `lvlvar'="52-Lampang" if `lvlvar'=="52"
				replace `lvlvar'="53-Uttaradit" if `lvlvar'=="53"
				replace `lvlvar'="54-Phrae" if `lvlvar'=="54"
				replace `lvlvar'="55-Nan" if `lvlvar'=="55"
				replace `lvlvar'="56-Phayao" if `lvlvar'=="56"
				replace `lvlvar'="57-Chiang Rai" if `lvlvar'=="57"
				replace `lvlvar'="58-Mae Hong Son" if `lvlvar'=="58"
				replace `lvlvar'="60-Nakhon Sawan" if `lvlvar'=="60"
				replace `lvlvar'="61-Uthai Thani" if `lvlvar'=="61"
				replace `lvlvar'="62-Kamphaeng Phet" if `lvlvar'=="62"
				replace `lvlvar'="63-Tak" if `lvlvar'=="63"
				replace `lvlvar'="64-Sukhothai" if `lvlvar'=="64"
				replace `lvlvar'="65-Phitsanulok" if `lvlvar'=="65"
				replace `lvlvar'="66-Phichit" if `lvlvar'=="66"
				replace `lvlvar'="67-Phetchabun" if `lvlvar'=="67"
				replace `lvlvar'="70-Ratchaburi" if `lvlvar'=="70"
				replace `lvlvar'="71-Kanchanaburi" if `lvlvar'=="71"
				replace `lvlvar'="72-Suphun Buri" if `lvlvar'=="72"
				replace `lvlvar'="73-Nakhon Pathom" if `lvlvar'=="73"
				replace `lvlvar'="74-Samut Sakhon" if `lvlvar'=="74"
				replace `lvlvar'="75-Samut Songkhram" if `lvlvar'=="75"
				replace `lvlvar'="76-Phetchaburi" if `lvlvar'=="76"
				replace `lvlvar'="77-Prachuap Khiri Kha" if `lvlvar'=="77"
				replace `lvlvar'="80-Nakhon Si Thammara" if `lvlvar'=="80"
				replace `lvlvar'="81-Krabi" if `lvlvar'=="81"
				replace `lvlvar'="82-Phangnga" if `lvlvar'=="82"
				replace `lvlvar'="83-Phuket" if `lvlvar'=="83"
				replace `lvlvar'="84-Surat Thani" if `lvlvar'=="84"
				replace `lvlvar'="85-Ranong" if `lvlvar'=="85"
				replace `lvlvar'="86-Chumphon" if `lvlvar'=="86"
				replace `lvlvar'="90-Songkhla" if `lvlvar'=="90"
				replace `lvlvar'="91-Satun" if `lvlvar'=="91"
				replace `lvlvar'="92-Trang" if `lvlvar'=="92"
				replace `lvlvar'="93-Phatthalung" if `lvlvar'=="93"
				replace `lvlvar'="94-Pattani" if `lvlvar'=="94"
				replace `lvlvar'="95-Yala" if `lvlvar'=="95"
				replace `lvlvar'="96-Narathiwat" if `lvlvar'=="96"

				replace `lvlvar' = "14-Phra Nakhon Si Ayu" if `lvlvar'=="14-Phra Nakhon Si Ayudhya"
				replace `lvlvar' = "11-Samut Prakan" if `lvlvar'=="11-Samut Prakarn"
				replace `lvlvar' = "23-Trat" if `lvlvar'=="23-Trad"
				replace `lvlvar' = "25-Prachin Buri" if `lvlvar'=="25-Phachinburi"
				replace `lvlvar' = "72-Suphun Buri" if `lvlvar'=="72-Suphanburi"
				replace `lvlvar' = "75-Samut Songkhram" if `lvlvar'=="75-Samut Songkham"
				replace `lvlvar' = "77-Prachuap Khiri Kha" if `lvlvar'=="77-Prachuap Khilikhan"
				replace `lvlvar' = "80-Nakhon Si Thammara" if `lvlvar'=="80-Nakhon Si Thammarat"
				
			}
			
			if "`code'"=="TUN"  {			
				replace `lvlvar' = "2 - NE" if `lvlvar'=="2 - Nord Est"
				replace `lvlvar' = "3 - NW" if `lvlvar'=="3 - Nord Ouest"
				replace `lvlvar' = "4 - CenterE" if `lvlvar'=="4 - Centre Est"
				replace `lvlvar' = "5 - CenterW" if `lvlvar'=="5 - Centre Ouest"
				replace `lvlvar' = "6 - SE" if `lvlvar'=="6 - Sud Est"
				replace `lvlvar' = "7 - SW" if `lvlvar'=="7 - Sud ouest"
			}
			
			if "`code'"=="UKR"  {	
				replace `lvlvar' = "21 – Transcarpathian" if `lvlvar'=="7 – Transcarpathian"
			}
			
			if "`code'"=="UZB"  {	
				replace `lvlvar' = "4-Jizzak" if `lvlvar'=="1708 -  Jizzakh"
				replace `lvlvar' = "11-Tashkent" if `lvlvar'=="1727 -  Tashkent (region)"
				replace `lvlvar' = "13-Khorezm" if `lvlvar'=="1733 -  Khorasm"
			}
			
			if "`code'"=="VNM"  {	
				replace `lvlvar' = "2-Midlands and Northern Mountainous Areas" if `lvlvar'=="1-North Mountain and Midland"			
				replace `lvlvar' = "3-Northern and Coastal Central Region" if `lvlvar'=="3-Northern and Coastal Central region_num"
				replace `lvlvar' = "3-Northern and Coastal Central Region" if `lvlvar'=="3-North Central area and South Central Coastal area"
				replace `lvlvar' = "6-Mekong Delta" if `lvlvar'=="6-Mekong River Delta"
				//8 regions into 6 regions
				replace `lvlvar' = "3-Northern and Coastal Central Region" if `lvlvar'=="Central North" | `lvlvar'=="Central South"			
				replace `lvlvar' = "4-Central Highlands" if `lvlvar'=="Highlands"
				replace `lvlvar' = "6-Mekong Delta" if `lvlvar'=="Mekong River Delta"
				replace `lvlvar' = "2-Midlands and Northern Mountainous" if `lvlvar'=="Northeast"
				replace `lvlvar' = "2-Midlands and Northern Mountainous" if `lvlvar'=="Northwest"
			}
			
			if "`code'"=="WSM"  {	
				replace `lvlvar' = "1-Apia Urban Areas" if `lvlvar'=="1-Apia"	
				replace `lvlvar' = "2-North West Upolu" if `lvlvar'=="2-NWU"	
				replace `lvlvar' = "3-Rest of Upolu" if `lvlvar'=="3-RoU"	
			}
			
			if "`code'"=="XKX"  {	
				egen sample3 = sieve(`lvlvar'), keep(a)
				gen sample3UP = upper(sample3)					
				replace `lvlvar'="1 -Gjakovע" if sample3UP== "GJAKOVE"			
				replace `lvlvar'="3 - Mitrovic" if sample3UP== "MITROVICE"			
				replace `lvlvar'="6 - Prishtin" if sample3UP== "PRISHTINE"			
				replace `lvlvar'="4 - Pej" if sample3UP== "PEJE"			
				drop  sample3 sample3UP
			}
			
			if "`code'"=="AZE"  {	
				egen sample3 = sieve(`lvlvar'), keep(a)
				gen sample3UP = upper(sample3)					
				replace `lvlvar'="" if sample3UP== "GJAKOVE"			
				
				replace `lvlvar'="1 – Absheron" if sample3UP== "ABERONQUBA"|sample3UP== "ABSHERON"|sample3UP== "ABSHERONGUBA"
				replace `lvlvar'="6 – Aran" if sample3UP== "ARANWITHYUHKARABAH"
				replace `lvlvar'="8 – Baku City" if sample3UP== "BAKU"|sample3UP== "BAKUCITY"
				replace `lvlvar'="9 – Daghlig Shirvan" if sample3UP== "DAGLIQSHIRVAN" | sample3UP== "SHIRVAN" |sample3UP== "IRVAN"|sample3UP== "DAGHLIGSHIRVAN"
				replace `lvlvar'="2 – Ganja-Gazakh" if sample3UP== "GANJAGAZAKH"
				replace `lvlvar'="5 – Guba-Khachmaz" if sample3UP== "GUBAHACHMAZ"
				replace `lvlvar'="4 – Lankaran" if sample3UP== "LANKARANASTARA"

				replace `lvlvar'="NA" if sample3UP== "MUANSALYAN"|sample3UP== "MUGHANSALYAN"
				replace `lvlvar'="0 – Nakhchyvan" if sample3UP== "NAKHCHIVAN"|sample3UP== "NAKHCHYVANAR"
				replace `lvlvar'="7 – Yukhary Garabagh" if sample3UP== "QARABAGHMIL"|sample3UP== "QARABAMIL"
				replace `lvlvar'="3 – Shaki-Zagatala" if sample3UP== "SHAKIZAGATALA"|sample3UP== "SHEKIZAGATALA"
				replace `lvlvar'="7 – Yukhary Garabagh" if sample3UP== "YUHARSKARABAH"	 | sample3UP== "YUKHARYGARABAGH"	
				drop  sample3 sample3UP
			}

		}
				
		//urban and rural
		local urbvar 
		cap des urban 
		if _rc==0 {
			ta urban
			if r(N)>0 {
				cap decode urban, gen(_urban_)
				if _rc~=0 tostring urban, gen(_urban_)
				replace _urban_ = trim(_urban_)	
				gen reg_rural = `oklist' + "*_*" + _urban_
				local urbvar reg_rural
			}
		} //urban
		
		local oklist2 _all_ `oklist' `urbvar'
		local oklist2 : list uniq oklist2
		
		****************************************************
		**Dimension 1: Poverty 
		****************************************************
		gen double gallT_ppp = welfare/cpi2017/icp2017/365
		drop if gallT_ppp<0
		replace gallT_ppp = 0.25 if gallT_ppp<0.25
		
		//reweight to lineup year pop
		su year [aw=`wgt']
		local initial = r(sum_w)
		gen double pop = (`wgt') * (`pcnpop'/`initial')
		
		//recalculate the 2.15 line for 2.15 poverty
		qui foreach num of numlist ${plinelist} {	
			if `pcnpov`num''==0 {
				local pline`num' = `=`num'/100'
			}
			else {
				_pctile gallT_ppp [aw=pop], p(`pcnpov`num'')
				local pline`num' = r(r1) 
			}
			
			gen poor`num'_ln = gallT_ppp < `pline`num'' if gallT_ppp~=.
			gen pline`num' = `pline`num''
		} //num	
							
		****************************************************
		**Dimension 2: Access to Education 
		****************************************************
		if `edu_flag'==1 { //data in survey
			**1a) Indicator: have no one with primary completion (completed 15+)
			//All adults
			global eduage 15
			if "`=upper("`code'")'" == "UKR" { //2014		
				global eduage 2 //2019
				drop age 
				*ren agecat age
				//check whether it is string or not
				//2019 only
				gen age = 1 if agecat=="1 - Up to 18 years"
				replace age = 2 if agecat=="2 - 18 - 35 years old"
				replace age = 3 if agecat=="3 - 36 - 55 years old"
				replace age = 4 if agecat=="4 - 56 - 59 years old"
				replace age = 5 if agecat=="5 - 60 years and older"
			}
			
			if "`=upper("`code'")'" == "NRU" { //2012
				global eduage 4 //2019
				drop age 
				*ren agecat age
				//check whether it is string or not
				//2012 only
				gen age = .					
				replace age = 1 if agecat=="0-4 years"
				replace age = 2 if agecat=="5-9 years"
				replace age = 3 if agecat=="10-14 years"
				replace age = 4 if agecat=="15-19 years"
				replace age = 5 if agecat=="20-24 years"
				replace age = 6 if agecat=="25-29 years"
				replace age = 7 if agecat=="30-34 years"
				replace age = 8 if agecat=="35-39 years"
				replace age = 9 if agecat=="40-44 years"
				replace age = 10 if agecat=="45-49 years"
				replace age = 11 if agecat=="50-54 years"
				replace age = 12 if agecat=="55-59 years"
				replace age = 13 if agecat=="60-64 years"
				replace age = 14 if agecat=="65-69 years"
				replace age = 15 if agecat=="70-74 years"
				replace age = 16 if agecat=="75 and older"
			}
			
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
				else {	//educat4
					cap su educat4
					if r(N)>0 {
						gen temp2 = 1 if age>=$eduage & age~=. & educat4>=2 & educat4~=.
						gen temp2c = 1 if age>=$eduage & age~=. & (educat4>=2 | educat4==.)
					}
					else { //no education available	
						local eduflag = 1					
					}
				}
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
		} //edu flag ==1		
		if `edu_flag'==2 { //universal coverage
			gen dep_educ_com = 0
		} //`edu_flag'==2		
		if `edu_flag'==3 { //fused in below
			gen dep_educ_com = .
		}
		if `edu_flag'==4 { //fused in below
			gen dep_educ_com = .
			gen unesco_flag = 1
		}
		
		****************************************************
		**Dimension 3: Access to Electricity 
		****************************************************		
		if `elec_flag'==1 { //data in survey
			cap des electricity
			if _rc==0 gen dep_infra_elec = electricity==0 if electricity~=.
			else local elec_flag 3
			*else gen dep_infra_elec = .	
		}
		if `elec_flag'==2 { //universal
			gen dep_infra_elec = 0
		}		
		if `elec_flag'==3 {
			gen dep_infra_elec = .
		}
		if `elec_flag'==4 {
			gen dep_infra_elec = .
			gen elec_flag = 1
		}
		la var dep_infra_elec "Deprived if HH has No access to electricity"
		
		****************************************************
		**Dimension 4: Access to Water 
		****************************************************				
		if `water_flag'==1 {
			cap des imp_wat_rec
			if _rc==0 gen dep_infra_impw = imp_wat_rec==0 if imp_wat_rec~=.		
			*else      gen dep_infra_impw = .			
			else 	  local water_flag 3
		}
		if `water_flag'==2 {
			gen dep_infra_impw = 0
		}		
		if `water_flag'==3 {
			gen dep_infra_impw = .
		}
		if `water_flag'==4 {
			gen dep_infra_impw = .
			gen water_flag = 1
		}
		la var dep_infra_impw "Deprived if HH has No access to improved water"

		****************************************************
		**Dimension 5: Access to social protection 
		****************************************************				
		if `sp_flag'==1 {
			//nothing yet from survey
		}
		if `sp_flag'==2 {
			gen dep_sp = 0			
		}
		if `sp_flag'==3 {
			gen dep_sp = .
		}
		if `sp_flag'==4 {
			gen dep_sp = .
			gen sp_flag = 1
			
		}
		****************************************************
		**Dimension 6: Access to financial inclusion
		****************************************************				
		if `findex_flag'==1 { // from surveys	 	 
			cap des fin_account
			if _rc==0 gen dep_fin = fin_account==0 if fin_account~=.		
			else      local findex_flag 3
		}
		if `findex_flag'==2 {
			gen dep_fin = 0			
		}
		if `findex_flag'==3 {
			gen dep_fin = .
		}
		if `findex_flag'==4 {
			gen dep_fin = .
			gen fin_flag = 1			
		}
		****************************************************		
		cap gen rural = urban==0
		
		//get 15+ population size by quintile or quintile/urban rural only when age is available.
		forv a1=1(1)5 {
			local n15q`a1'total = 1
			local n15q`a1'urban = 1
			local n15q`a1'rural = 1
		}
		
		qui if "`mod'"=="ALL" {		
			_ebin gallT_ppp [aw=pop], gen(q5ind) nq(5)		
			cap des age
			if _rc==0 {
				qui su age
				if r(N)>0 {
					gen tmp = age>=15 & age~=.
					bys hhid (pid): egen n15 = total(tmp)
					//`no_accountq`i'`nm'' `no_accountq`i'total'
					forv a1=1(1)5 {
						su n15 [aw=pop] if q5ind==`a1'
						local n15q`a1'total = r(mean)
						if `ct_urban'==1 {
							su n15 [aw=pop] if q5ind==`a1' & urban==1
							local n15q`a1'urban = r(mean)
						
							su n15 [aw=pop] if q5ind==`a1' & urban==0
							local n15q`a1'rural = r(mean)							
						} //ct_urban			 			
					} //a1
				} //rN
			} //age
			cap drop q5ind tmp n15
		} //ALL
		
		//POP WEIGHT at HH level - to convert all data to HH level as data comes in as either individual or HH level data
		set varabbrev off			
		cap isid hhid
		if _rc==0 {
			cap des pop
			if _rc==0 gen double pop2 = pop
			else gen double pop2 = weight_p
		}
		else {
			cap des pop
			if _rc==0 {
				drop if welfare==. 
				drop if pop==.						
				bys hhid: egen double pop2 = total(pop)						
			}
			else {
				drop if welfare==. 
				drop if weight_p==.						
				bys hhid: egen double pop2 = total(weight_p)
			}							
			duplicates drop hhid, force
		}
		set varabbrev on
		ren pop popold
		ren pop2 pop
		
		cap drop region	
		gen region = "`regn'"	
		cap drop survname
		gen str survname = "`survname'"
		local welfaretype : char _dta[welfaretype]	
		clonevar weight_use = pop
		
		//quintiles
		_ebin gallT_ppp [aw=pop], gen(q5) nq(5)		
		gen test = 1
	
		tempfile databfsim
		save `databfsim', replace
			
		//Data fusion loop through random assignments
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
			**************************************************** FUSION		
			
			//Education
			if `edu_flag'==3 {
				if `unesco'==1 {
					gen unesco_flag = 0
					if "`type_unesco'"=="Urb_rur" { //urban-rural only							
						foreach nm in urban rural {							
							cap drop _a1
							if (`unesco_`nm'' > 0) {				
								wsample test [aw=pop] if `nm'==1, percent(`unesco_`nm'') newvar(_a1) seed(`=1234567+`sim'') numsim(1)
							}
							else {
								gen _a1 = 0 if `nm'==1			
							}							
							replace dep_educ_com = 1- _a1 if  `nm'==1
							drop _a1														
						} //urb-rul
					}
					else { //total country
						local nm total						
						cap drop _a1
						if (`unesco_`nm'' > 0) {				
							wsample test [aw=pop] , percent(`unesco_`nm'') newvar(_a1) seed(`=1234567+`sim'') numsim(1)
						}
						else {
							gen _a1 = 0 
						}							
						replace dep_educ_com = 1- _a1 
						drop _a1
					} //types
				}
				else { //missing					
					gen unesco_flag = 1
				} 
			}
			
			//Electricity
			if `elec_flag'==3 {
				if `ged'==1 {
					gen elec_flag = 0
					if "`type_ged'"=="Urb_rur" { //urban-rural only							
						foreach nm in urban rural {							
							cap drop _a1
							if (`ged_`nm'' > 0) {				
								wsample test [aw=pop] if `nm'==1, percent(`ged_`nm'') newvar(_a1) seed(`=1234567+`sim'') numsim(1)
							}
							else {
								gen _a1 = 0 if `nm'==1			
							}							
							replace dep_infra_elec = 1- _a1 if  `nm'==1
							drop _a1														
						} //urb-rul
					}
					else { //total country
						local nm total						
						cap drop _a1
						if (`ged_`nm'' > 0) {				
							wsample test [aw=pop] , percent(`ged_`nm'') newvar(_a1) seed(`=1234567+`sim'') numsim(1)
						}
						else {
							gen _a1 = 0 
						}							
						replace dep_infra_elec = 1- _a1 
						drop _a1
					} //types
				}
				else { //missing					
					gen elec_flag = 1
				} 
			} //elec_flag
			
			//Water
			if `water_flag'==3 {
				if `jmp'==1 {
					gen water_flag = 0
					if "`type_jmp'"=="Urb_rur" { //urban-rural only							
						foreach nm in urban rural {							
							cap drop _a1
							if (`w_imp_`nm'' > 0) {				
								wsample test [aw=pop] if `nm'==1, percent(`w_imp_`nm'') newvar(_a1) seed(`=1234567+`sim'') numsim(1)
							}
							else {
								gen _a1 = 0 if `nm'==1			
							}							
							replace dep_infra_impw = 1- _a1 if  `nm'==1
							drop _a1														
						} //urb-rul
					}
					else { //total country
						local nm total						
						cap drop _a1
						if (`w_imp_`nm'' > 0) {				
							wsample test [aw=pop] , percent(`w_imp_`nm'') newvar(_a1) seed(`=1234567+`sim'') numsim(1)
						}
						else {
							gen _a1 = 0 
						}							
						replace dep_infra_impw = 1- _a1 
						drop _a1
					} //types
				}
				else { //missing					
					gen water_flag = 1
				} 
			} //water_flag
			
			//Findex fusion
			if `findex_flag'==3 { //findex access no_accountq`i'total				
				if `findex'==1 {					
					gen fin_flag = 0									
					//Add adjustment of individual level estimate to HH level estimate. N is number of 15+ in the group (national, quintile, or quitile & urban/rural). When the data is without age to figure n15, N==1, just hh = ind^0.6
					//hh = ind^(0.6*N)
					if "`type_findex'"=="Urb_rur" { //urban-rural quintiles						
						foreach nm in urban rural {
							forv i=1(1)5 {															
								cap drop _a`i'
								if (`no_accountq`i'`nm'' > 0) {																			
									*wsample test [aw=pop] if q5==`i' & `nm'==1, percent(`no_accountq`i'`nm'') newvar(_a`i') seed(`=1234567+`i'*`sim'') numsim(1)
									local adjfin = 100*((`=`no_accountq`i'`nm''/100')^(0.6*`n15q`i'`nm''))									
									wsample test [aw=pop] if q5==`i' & `nm'==1, percent(`adjfin') newvar(_a`i') seed(`=1234567+`i'*`sim'') numsim(1)
								}
								else {
									gen _a`i' = 0 if q5==`i' & `nm'==1			
								}
								replace dep_fin = _a`i' if q5==`i' & `nm'==1
								drop _a`i'								
							} //i
						} //urb-rul
					} //urb-rul quintiles
					else { //total quintiles						
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
					} //types					
				} //findex
				else { //missing					
					gen fin_flag = 1
				} 
			} //findex flag
						
			//SP access 
			if `sp_flag'==3 {
				if `aspire_sp'==1 {						
					gen sp_flag = 0
					
					if "`type_aspire'"=="Quintile" {
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
					} //quintile type
					else { //type_aspire == National						
						cap drop _a1
						if (`_pop_All_SPL' > 0) {				
							wsample test [aw=pop], percent(`_pop_All_SPL') newvar(_a1) seed(`=1234567+`sim'') numsim(1)
						}
						else {
							gen _a1 = 0
						}
						replace dep_sp = 1-_a1 
						drop _a1
					}
				} //aspire_sp==1
				else { //missing					
					gen sp_flag = 1
				}
			} //sp_flag==3
			**************************************************** END FUSION		
			
			//multidimensional vulnerability
			foreach num of numlist ${plinelist}  {
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
			
			gen sim = `sim'
			gen _count=1

			//collapse to get indicators
			compress
			tempfile data2
			save `data2', replace
						
			foreach var of local oklist2 {
				use `data2', clear
				clonevar h = pop
				clonevar h_ln = pop
				clonevar wta_pov = pop	
				replace `var' = strtrim(`var')
				replace `var' = ustrtrim(`var')
				replace `var' = strproper(`var')	
				
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
				gen region = "`regn'"	
				gen str welfaretype = "`welfaretype'"
				
				append using `ctry1ln'			
				order region code baseyear lineupyear survname welfaretype level sample sim poor* multvul_* all6vul_* all5vul_* all4vul_* all3vul_* all2vul_* dep_* pov1_* dim6*  total* sh_* nohh noind
				save `ctry1ln', replace
			} //foreach
			
			if (mod(`sim',50)==0){
				noi display in white ".  `sim'" _continue
				noi display _n(0)
			}
			else noi display "." _continue
		} //sim
		//collapse across sim
		
		//save results
		use `ctry1ln', replace
		compress
		save "${upath2}\03.intermediate\Sim\\${lnyear}\\temp\\`code'_`baseyear'_`survname'_${lnyear}_lnsim", replace
		
		groupfunction, mean(poor* multvul_* all6vul_* all5vul_* all4vul_* all3vul_* all2vul_* dep_* pov1_* dim6* mean_ln total* sh_* nohh noind) by(code baseyear lineupyear survname level sample)
		gen todo = `todo'
		order code survname level sample baseyear lineupyear todo mean_ln poor215_ln poor685_ln dep_* multvul_* all*vul* pov1* dim6* total* sh_* nohh noind
		save "${upath2}\03.intermediate\Sim\\${lnyear}\\`code'_`baseyear'_`survname'_${lnyear}", replace
		
		append using "${upath2}\03.intermediate\Sim\Vintages\\`fdataall_ln'"
		compress
		save "${upath2}\03.intermediate\Sim\Vintages\\`fdataall_ln'", replace 
	} //dlw rc
	else {
		noi dis "`j' - Failed to load DLW `code'-`surv_year'-`survname'-`mod'"
	}			
} //forvalue i
log close

/*
use `dataall', clear
compress
save "${maindir}/output/sub_base", replace

use `dataall_ln', clear
compress
save "${maindir}/output/sub_base_ln", replace
*/
