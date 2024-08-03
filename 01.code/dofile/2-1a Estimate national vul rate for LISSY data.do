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

*************************************************************************
*LISSY Vul - national level - Need to copy the code to run on LISSY
*Results will sent by email, clean it and run next steps
*************************************************************************

clear 
input str3 code year str4 file cpi2017 icp2017 pov215 pov365 pov685
AUS	2018	au18	1.019114	1.5293353	0.4971	0.7382	0.9843
CAN	2019	ca19	1.0426171	1.2866648	0.2486	0.4995	0.7154
DEU	2020	de20	1.0335239	.7871803	0.2438	0.2438	0.4711
GBR	2021	uk21	1.0774739	.77973002	0.2451	0.4983	0.7377
ISR	2021	il21	1.0255175	4.2066031	0.2422	0.9950	3.4907
KOR	2021	kr21	1.0497039	974.20563	0.0000	0.2488	0.4979
TWN	2021	tw21	1.0367744	16.597717	0.0000	0.0000	0.2474
USA	2021	us21	1.1054594	1	0.2487	0.4963	0.9996
end

replace file = trim(file)
local all= _N
tempfile data1
save `data1', replace

global plinelist 215 365 685

qui forv i=1(1)`all' { 
	
		use `data1', clear 
		local code = code[`i'] 
		local year = year[`i'] 		
		local cpi2017 = cpi2017[`i'] 
		local icp2017 = icp2017[`i'] 
		foreach num of numlist ${plinelist}  {
			local pov`num' = pov`num'[`i'] 			
		}
		
		local x = file[`i'] 
		
		use ${`x'h}, clear    
		gen code = "`code'" 
	
		// urban dummy   
		gen urban= (rural==0)   
		   
		// welfare variable     
		qui drop if dhi<0   
		qui drop if dhi == .       
		qui gen welfare = dhi/nhhmem/`cpi2017'/`icp2017'/365   
		replace welfare = 0.25 if welfare<0.25
		
		//merge with person-level file   
		qui collapse year rural hpopwgt nhhmem welfare, by(dname code hid region_c)   
		qui sum year   
		qui local y = substr("`r(mean)'", 3,.)     
	  
		qui merge 1:m hid using ${`x'p}, keepusing(pid ppopwgt age educlev illiterate enroll lfs inda1 sex) nogenerate    
			
		//subnatid
		cap des region_c
		qui if _rc==0 {
			cap decode region_c, gen(region_c1)
			if _rc~=0 tostring region_c, gen(region_c1)			
			replace region_c1 = trim(region_c1)
			
			//recode region for ISR
			if "`code'"=="ISR" {						
				replace region_c1 = "North" if region_c1=="[21]North: Zefat" | region_c1=="[21]North: Zefat, Kineret & Golan" | region_c1=="[22]North: Kinneret" | region_c1=="[23]North: Yizrael" | region_c1=="[23]North: Yizrael-Afula" | region_c1=="[24]North: Acre" | region_c1=="[25]North: Yizrael-Nazareth" | region_c1=="[29]North: Golan"

				replace region_c1 = "Haifa" if region_c1=="[31]Haifa: Haifa" | region_c1=="[32]Haifa: Hadera"

				replace region_c1 = "Center" if region_c1=="[41]Center: Sharon"|region_c1=="[42]Center: Petah Tiqwa"| region_c1=="[42]Center: Petah-Tikva"| region_c1=="[43]Center: Ramla" | region_c1=="[44]Center: Rehovot"

				replace region_c1 = "Tel Aviv" if region_c1=="[51]Tel aviv: Tel Aviv" |region_c1=="[52]Tel Aviv: Ramat Gan" | region_c1=="[52]Tel aviv: Ramat-gan" | region_c1=="[53]Tel aviv: Holon"|region_c1=="[51]Tel Aviv: Tel Aviv" |region_c1=="[53]Tel Aviv: Holon"
				
				replace region_c1 = "South" if region_c1=="[61]South: Ashkelon" | region_c1=="[61]South: Ashqelon" | region_c1=="[62]South: Be'er Sheva"	
			}
			
			drop region_c
			ren region_c1 region_c
			
			//truncate region_c to 32 characters
			replace region_c = substr(region_c,1,32)
		} //region_c
		else {
			gen region_c = "MISSING"
		}
			
		*decode rural, gen(rural2)
		*replace rural2 = trim(rural2)
		gen reg_rural = region_c + "*_*"+string(rural)	
		gen _all_ = "All Sample"
		
		/**************************************   
		0. Generate comparable education vars   
		**************************************/   
		qui gen educat4 = 1 if inlist(educlev,111)   
		qui replace educat4 = 2 if inlist(educlev,110,120)   
		qui replace educat4 = 3 if inlist(educlev,130,210)   
		qui replace educat4 = 4 if inlist(educlev,311,312,313,320)   
		   
		qui gen educat5 = 1 if inlist(educlev,111)   
		qui replace educat5 = 2 if inlist(educlev,110)   
		qui replace educat5 = 3 if inlist(educlev,120,130)   
		qui replace educat5 = 4 if inlist(educlev,210)   
		qui replace educat5 = 5 if inlist(educlev,220,311,312,313,320)   
		   
		qui gen educat7 = 1 if inlist(educlev,111)   
		qui replace educat7 = 2 if inlist(educlev,110)   
		qui replace educat7 = 3 if inlist(educlev,120)   
		qui replace educat7 = 4 if inlist(educlev,130)   
		qui replace educat7 = 5 if inlist(educlev,210)   
		qui replace educat7 = 6 if inlist(educlev,220,311)   
		qui replace educat7 = 4 if inlist(educlev,312,313,320)   
		   
		// school dummy   
		qui gen school = (enroll==1)   
		   
		// agricultural worker dummy   
		qui gen agri = (inda1==1)   
		   
		// labor force variable   
		qui gen lstatus1 = lfs==100   
		qui gen lstatus2 = lfs==200   
		qui gen lstatus3 = inlist(lfs,300,310,320,330,340)   
		   
		// male dummy   
		qui gen male = (sex==1)   
		   
		/***********************************   
		**Dimension 1:  Education   
		***********************************/   
		   
		**1a) Indicator: no one in hh with primary completion (age 15+)   
		//All adults   
		qui global eduage 15   
		qui local eduflag = 0   
		qui cap gen educat5 = .   
		qui cap gen educat7 = .   
		   
		qui cap su educat7   
		qui if r(N)>0 {   
			gen temp2 = 1 if age>=$eduage & age~=. & educat7>=3 & educat7~=.   
			gen temp2c = 1 if age>=$eduage & age~=. & (educat7>=3 | educat7==.)   
		}
		qui else { //educat5   
			cap su educat5   
			if r(N)>0 {   
				gen temp2 = 1 if age>=$eduage & age~=. & educat5>=3 & educat5~=.   
				gen temp2c = 1 if age>=$eduage & age~=. & (educat5>=3 | educat5==.)   
			}
			else { //educat4   
				cap su educat4   
				if r(N)>0 {   
					gen temp2 = 1 if age>=$eduage & age~=. & educat4>=2 & educat4~=.   
					gen temp2c = 1 if age>=$eduage & age~=. & (educat4>=2 | educat4==.)   
				}
				else { //no education available    
					local eduflag = 1    
				}
			} //educat4   
		}
		   
		qui if `eduflag'==0 {    
			gen temp2a = 1 if age>=$eduage & age~=.   
			bys hid: egen educ_com_size = sum(temp2a)   
			bys hid: egen temp3 = sum(temp2)   
			bys hid: egen temp3c = sum(temp2c)   
			gen dep_educ_com = 0   
			replace dep_educ_com = 1 if temp3==0   
			gen dep_educ_com_lb = 0   
			replace dep_educ_com_lb = 1 if temp3c==0   
			ren temp3 educ_com_sum   
			ren temp3c educ_com_sum_lb   
			drop temp2 temp2a temp2c   
		}
		qui else { 
			gen dep_educ_com = .   
			gen dep_educ_com_lb = .   
			gen educ_com_sum = .   
			gen educ_com_sum_lb = .   
			gen educ_com_size = .    
		}
		   
		qui gen educ_com_appl = 1   
		qui replace educ_com_appl = 0 if (educ_com_size==0 | educ_com_size==.)   
		qui gen temp2b = 1 if age>=$eduage & age~=. & educat4==. & educat5==. & educat7==.   
		qui bys hid: egen educ_com_mis = sum(temp2b)   
		qui drop temp2b   
		qui gen educ_com_appl_miss = educ_com_appl == 1 & educ_com_mis>0 & educ_com_mis~=.   
		   
		qui la var dep_educ_com "Deprived if Households with NO adults $eduage+ with no primary completion"   
		qui la var dep_educ_com_lb "Deprived if Households with NO adults $eduage+ with no or missing primary completion"   
		qui la var educ_com_appl "School completion is applicable households, has $eduage or more individuals"   
		qui la var educ_com_appl_miss "School completion is applicable households but missing completion"   
		cap drop  dep_educ_com_lb educ_com_appl educ_com_appl_miss
		****************************************************   
		**Dimension 2: Access to infrastructure    
		****************************************************   
		
		****************************************************   
		//Indicator: Electricity   
		gen dep_infra_elec = 0   
		qui la var dep_infra_elec "Deprived if HH has No access to electricity"   
		   
		****************************************************    
		//Indicator: Water     
		gen dep_infra_impw = 0    
		qui la var dep_infra_impw "Deprived if HH has No access to improved water"   
		   
		****************************************************   
		**Dimension 3: Monetary    
		****************************************************   
		//recalculate the 2.15 line for 2.15 poverty
		qui foreach num of numlist ${plinelist}  {		
			if `pov`num''==0 {
				local pline`num' = `=`num'/100'
			}
			else {
				_pctile welfare [aw=hpopwgt], p(`pov`num'')
				local pline`num' = r(r1) 
			}
			
			gen poor`num'_ln = welfare < `pline`num'' if welfare~=.
			gen pline`num' = `pline`num''
		} //num	
		   
		//findex
		gen dep_fin = 0

		//social protection
		gen dep_sp = 0
		
		qui gen file = dname   
		gen _count = 1
		gen h = hpopwgt
		//multidimensional vulnerability
		foreach num of numlist ${plinelist}  {		
			//vulnerable and one dim			
			gen p1_edu_`num' = 0
			replace p1_edu_`num' = 1 if poor`num'_ln==1 & dep_educ_com==1
			
			gen p1_sp_`num' = 0
			replace p1_sp_`num' = 1 if poor`num'_ln==1 & dep_sp==1
			
			gen p1_fin_`num' = 0
			replace p1_fin_`num' = 1 if poor`num'_ln==1 & dep_fin==1
			
			gen p1_elec_`num' = 0
			replace p1_elec_`num' = 1 if poor`num'_ln==1 & dep_infra_elec==1
			
			gen p1_water_`num' = 0
			replace p1_water_`num' = 1 if poor`num'_ln==1 & dep_infra_impw==1
			
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
		
		
		collapse (mean) welfare  poor* multvul_* all6vul_* all5vul_* all4vul_* all3vul_* all2vul_* dep_* p1_* dim6* (rawsum) _count h [aw=hpopwgt], by(file year _all_) 
			 
		gen data_`x' = 1
	global reglvl _all_
	
	//tables 
	noi dis "`code'-`year' - `x'" 
	noi table ${reglvl} , c(mean welfare mean dep_infra_elec mean dep_infra_impw mean dep_fin mean dep_sp)  format(%15.0g) missing 
	noi table ${reglvl} , c(mean dep_educ_com mean _count mean h)  format(%15.0g) missing 
	
	foreach num of numlist ${plinelist}  {
		noi table ${reglvl} , c(mean poor`num'_ln mean dim6_`num' mean multvul_`num')  format(%15.0g) missing 
		noi table ${reglvl} , c(mean p1_edu_`num' mean p1_sp_`num' mean p1_fin_`num' mean p1_elec_`num' mean p1_water_`num')  format(%15.0g) missing 
		noi table ${reglvl} , c(mean all2vul_`num' mean all3vul_`num' mean all4vul_`num' mean all5vul_`num' mean all6vul_`num')  format(%15.0g) missing 
	}
	
} //end loop all


	   	   
