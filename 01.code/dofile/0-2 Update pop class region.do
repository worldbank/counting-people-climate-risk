//POP, PIP region, and income class
clear

tempfile pop pce gdp data1 data2 data3
global ver 20240326_2017_01_02_PROD

tempfile pop
pip tables, table(pop) server(prod) version($ver) clear
*replace value = "" if value=="NA"
*destring value, replace
gen double pop = value/1000000
drop value
reshape wide pop, i(country_code year) j( data_level) string
ren popnational pop
ren poprural pop_rural 
ren popurban pop_urban
  
ren country_code code
gen year_data = year

merge 1:1 code year_data using "${upath2}\02.input\CLASS"
drop if _merge==1
drop _merge

save "${upath2}\\02.input\code_inc_pop_regpcn", replace
