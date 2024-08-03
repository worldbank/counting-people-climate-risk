*! wsample June 14, 2018
* Paul Corral (World Bank Group - Poverty and Equity Global Practice)

cap prog drop wsample
program define wsample, eclass
	version 11.2
	#delimit;
	syntax varlist (max=1 numeric) [if] [in] [aw], 
	newvar(string)
	[percent(numlist max=1 >0)
	value(numlist max=1 >0)
	numsim(integer 1)
	seed(string)];
#delimit cr		
marksample touse

//Either value or percent
if ("`value'"!="" & "`percent'"!=""){
	dis as error "Only one option is available either value or percent"
	error 119
}
	//Weights
	if "`exp'"=="" {
		tempvar w
		qui:gen `w' = 1
		local wvar `w'
	}
	else{
		tempvar w 
		qui:gen double `w' `exp'
	}

mata: st_view(x1=., ., "`varlist'","`touse'")
mata: st_view(w1=., ., "`w'","`touse'")

if ("`percent'"!=""){
	if (`percent'>100){
		dis as error "You have specified a value greater than 100 percent."
		error 119		
	}
	qui: sum `w' if `touse'
	local ccu = r(sum)*(`percent'/100)
	dis in green "Value for target percent: `ccu'"
}
else{
	local ccu = `value'
	dis in green "Target value: `ccu'"
}

if (`numsim'==1){
	qui:gen double `newvar' = .
	local mylist `mylist' `newvar'
}
else{
	forval z=1/`numsim'{
		qui:gen double `newvar'_`z' = .
		local mylist `mylist' `newvar'_`z'
	}
}
if ("`seed'"=="") set seed 69374255
else set seed `seed'
//dis as error "_RanDomaSSign(x1,w1,`ccu',`numsim')"
mata: st_store(.,st_varindex(tokens("`mylist'")),"`touse'",_RanDomaSSign(x1,w1,`ccu',`numsim'))

dis in green "Your new variable has been created in `newvar'*"	
end

cap set matastrict off
mata
//Function to create sim# permutation vectors
function _RanDomaSSign(x,w,cut,sim){

	data = runningsum(J(rows(x),1,1)),x,w,runiform(rows(x),sim)  //current order
	
	s=cols(data)
	
	//randomize assignment
	for(i=4;i<=s;i++){
	_sort(data,i)	
	data[.,i] = ((runningsum(data[.,3])):<=cut):*data[.,2]
	}
	_sort(data,1)
	return(data[|.,4 \ .,cols(data)|])
}
end
