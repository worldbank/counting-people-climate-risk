//ASPIRE - the data is only unique
clear
*global upath2 

import excel using "${upath2}\02.input\ASPIRE\ASPIRE_data_touse.xlsx" , clear firstrow sheet(Data_ver2)

gen type= ""
replace type = "Quintile" if _pop_All_SPL_q1~=. & _pop_All_SPL_q2~=. & _pop_All_SPL_q3~=. & _pop_All_SPL_q4~=. & _pop_All_SPL_q5~=.
replace type = "Urb" if _pop_All_SPL_q1==. & _pop_All_SPL_q2==. & _pop_All_SPL_q3==. & _pop_All_SPL_q4==. & _pop_All_SPL_q5==. & _pop_All_SPL_rur==. & _pop_All_SPL_urb~=.
replace type = "Rur" if _pop_All_SPL_q1==. & _pop_All_SPL_q2==. & _pop_All_SPL_q3==. & _pop_All_SPL_q4==. & _pop_All_SPL_q5==. & _pop_All_SPL_rur~=. & _pop_All_SPL_urb==.
replace type = "Urb_rur" if _pop_All_SPL_q1==. & _pop_All_SPL_q2==. & _pop_All_SPL_q3==. & _pop_All_SPL_q4==. & _pop_All_SPL_q5==. & _pop_All_SPL_rur~=. & _pop_All_SPL_urb~=.
replace type = "Total" if _pop_All_SPL_q1==. & _pop_All_SPL_q2==. & _pop_All_SPL_q3==. & _pop_All_SPL_q4==. & _pop_All_SPL_q5==. & _pop_All_SPL_rur==. & _pop_All_SPL_urb==. & _pop_All_SPL~=.

compress
isid code
saveold "${upath2}\02.input\2021\ASPIRE_data_2021.dta", replace