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
version 18
global rnd AM24
global lnyear 2021
tempfile data1 data2 data3 fullctry missreg dataall

*global upath2 

global fileout Tables.xlsx

/* OLD exposure only without spatial vulnerability
use "${upath2}\\04.output\Exp_vul_${lnyear}_raw", clear
gen multvul_215_exp = multvul_215*exposure 
gen all2vul_215_exp = all2vul_215*exposure 
*/

use "${upath2}\\04.output\Exp_vul_rai_${lnyear}_raw", clear
//todo = 1 is the list of countries with all dimensions, which is 104 countries.
replace dep_educ_com = 0 if code=="KOR" & dep_educ_com==.

//expose and vulnerable (both HH vulnerable and spatial vulnerable)
foreach var of varlist multvul_215 all2vul_215 multvul_365 all2vul_365 multvul_685 all2vul_685  {
	gen double `var'_exp = exprai_ + (exp_ - exprai_)*`var'	
}

foreach var of varlist poor215_ln poor365_ln poor685_ln dep_educ_com dep_infra_elec dep_infra_impw dep_sp dep_fin {
	gen double `var'_exp = (exp_ )*`var'	
}

// totalpop_rai: total population with spatial vulnerability
// exprai_ : exposed and spatial vulnerability

gen multvul_215_expold = multvul_215*exp_
*collect: table (scenario hazard), statistic(sum multvul_215_exp  multvul_215_expold  totalpop totalpop_rai) nototal nformat(%4.0f)

//Table WLD
collect: table (scenario hazard), statistic(sum multvul_215_exp exp_   totalpop) nototal nformat(%4.2f)
*collect: table (scenario hazard), statistic(sum multvul_215_exp exp_ multvul_215_expold all2vul_215_exp totalpop) nototal nformat(%4.2f)
collect style header scenario hazard , title(hide)
collect preview
s
collect export "${upath2}\\04.output\\${fileout}", sheet(WLD, replace) modify

//Single dimension
collect: table (scenario hazard), statistic(sum poor215_ln_exp poor365_ln_exp poor685_ln_exp dep_educ_com_exp dep_infra_elec_exp dep_infra_impw_exp dep_sp_exp dep_fin_exp  exprai_ totalpop) nototal nformat(%4.0f)
collect style header scenario hazard , title(hide)
collect preview

su poor215_ln poor685_ln dep_educ_com dep_infra_elec dep_infra_impw dep_sp dep_fin [aw=sh_pop*pop_pip] if hazard=="any" & scenario=="RP100*"

collect: table (scenario hazard), statistic(sum totalpop_rai exprai_ totalpop) nototal nformat(%4.0f)
* 2%  of popultion is spatial vulnerable. and 1% of population is exposed and spatial vulnerable

//Country level - any hazard and RP100
collect: table (code)  () if hazard=="any" & scenario=="RP100*", statistic(sum multvul_215_exp  all2vul_215_exp totalpop)  nformat(%4.0f)
collect style header code , title(hide)
collect preview
collect export "${upath2}\\04.output\\${fileout}", sheet(Country_any_RP100, replace) modify

sss
table (scenario hazard), statistic(sum multvul_215_exp  all2vul_215_exp totalpop) nototal nformat(%4.0f)

collect: table (pcn_region_code  ) (exp2)  if (vul2==1 & line==215) , statistic(sum nvul ) nototal nformat(%4.0f)

