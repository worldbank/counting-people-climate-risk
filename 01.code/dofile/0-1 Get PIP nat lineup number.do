//Get PIP lineup numbers
global dataout "${upath2}\03.intermediate\PIPinput\" 
//only for Aug-Sep running
global piptxt server(qa) version(20240627_2017_01_02_PROD)
			  
global ylist 2010 2015 2019 2020 2021 2022
global plines 215 365 685 322 547 1027 430 730 1370
foreach year of global ylist {
	foreach num of global plines  {		
		pip, country(all) year(`year') fillgap povline(`=`num'/100') ${piptxt} clear
		replace headcount = headcount*100
		drop if country_code=="CHN" & (reporting_level=="urban"|reporting_level=="rural")
		drop if country_code=="IND" & (reporting_level=="urban"|reporting_level=="rural")
		drop if country_code=="IDN" & (reporting_level=="urban"|reporting_level=="rural")		
		isid country_code
		saveold "${dataout}\PIP_`year'_`num'.dta", replace
	}
}

