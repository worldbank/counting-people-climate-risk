*! 1.4.0 NJC 27 Jan 2023 
* 1.3.0 NJC 3 Sep 2020 
* 1.2.0 NJC 11 Jun 2017 
* 1.1.1 NJC 11 May 2017 
* 1.1.0 NJC 26 Apr 2017 
* 1.0.1 NJC 24 Sep 2015
* 1.0.0 NJC 26 Aug 2015
program missings, rclass byable(recall) 
	version 12 

	// identify subcommand
	gettoken cmd 0 : 0, parse(" ,") 
	local l = length("`cmd'")

	if `l' == 0 {
		di "{err}subcommand needed; see help on {help missings}"
		exit 198
	}

	// report breakdown list table tag dropvars dropobs  
	if substr("report", 1, max(1, `l')) == "`cmd'" {
		local cmd "report"
	}
	else if substr("breakdown", 1, max(1, `l')) == "`cmd'" {
		local cmd "breakdown" 
	} 
	else if substr("list", 1, max(1, `l')) == "`cmd'" {
		local cmd "list"
	}
	else if substr("table", 1, max(3, `l')) == "`cmd'" {
		local cmd "table"
	}
	else if "tag" == "`cmd'" {
		* -t- or -ta- would be ambiguous
		if _by() error 190 
	}
	else if "dropvars" == "`cmd'" {
		* destructive subcommand spelled out 
		if _by() error 190 
	}
	else if "dropobs" == "`cmd'" {
		* destructive subcommand spelled out 
		if _by() error 190 
	}
	else {
		di "{err}illegal {cmd}missings {err}subcommand"
		exit 198
	}

	// check rest of syntax
	local common NUMeric STRing SYSmiss noHEADER 

	if "`cmd'" == "report" { 
		syntax [varlist(default=none)] [if] [in] ///
		[ , `common' OBServations MINimum(numlist max=1 >=0) ///
		Percent Format(str) SORT SORT2(str asis) SHOW(numlist int min=1 >0)  ///
		IDentify(varlist) * ]

		if "`format'" == "" local format %5.2f 

		// not considered an error, just a misunderstanding! 
		if "`identify'" != "" & "`observations'" == "" {
			noi di "identify() option ignored without observations option" 
		} 
	}
	else if "`cmd'" == "breakdown" { 
		syntax [varlist(default=none)] [if] [in] ///
		[, `common' MINimum(numlist max=1 >=0) ///
		SORT SORT2(str asis) SHOW(numlist int min=1 >0) *]
	} 
	else if "`cmd'" == "list" { 
		syntax [varlist(default=none)] [if] [in] ///
		[ , `common' MINimum(numlist max=1 >=0) IDentify(varlist) * ]
	}
	else if "`cmd'" == "table" { 
		syntax [varlist(default=none)] [if] [in] ///
		[ , `common' MINimum(numlist max=1 >=0) IDentify(varlist) * ]
	}
	else if "`cmd'" == "tag" { 
		syntax [varlist(default=none)] [if] [in], ///
		Generate(str) [`common']  

		capture confirm new variable `generate' 
		if _rc { 
			di as err "generate() must specify new variable" 
			exit _rc 
		}
	}	
	else if "`cmd'" == "dropvars" { 
		syntax [varlist] [, `common'  force ]

		if "`force'" == "" & c(changed) { 
			di as err "force option required with changed dataset"
			exit 4 
		}   
	}
	else if "`cmd'" == "dropobs" { 
		syntax [varlist] [if] [in] [, `common'  force] 

		if "`force'" == "" & c(changed) { 
			di as err "force option required with changed dataset"
			exit 4
		}   
	}

	// check syntax for sort options if specified 
	if "`sort'`sort2'" != "" {
		if "`sort'" != "" local sort missing descending 
		local sort `sort' `sort2' 

		foreach opt in missing alpha descending { 
			local `opt' 0 
		} 

		foreach word of local sort { 
			local word = lower("`word'") 
			local length = length("`word'")

			if "`word'" == substr("missings", 1, `length') {
				local missing 1 
			} 
			else if "`word'" == substr("alpha", 1, `length') { 
				local alpha 1 
			} 
			else if "`word'" == substr("descending", 1, `length') {  
				local descending 1 
			}
			else { 
				di as err "sort() option invalid?" 
				exit 198
			}
		}

		local tosort = `alpha' + `missing' 
		if `tosort' > 1  | (`tosort' == 0 & `descending') { 
			di as err "sort request invalid"
			exit 198 
		}
	} 

	quietly { 
		// which variables are we looking at? 
		if "`varlist'" == "" { 
			local vartext "{txt} all variables"
			unab varlist : _all
			if _by() local varlist : ///
			subinstr local varlist "`_byindex'" "" 
		} 

		if "`numeric'`string'" != "" { 
			if "`numeric'" != "" & "`string'" != "" { 
				* OK 
			} 
			else { 
				if "`numeric'" != "" ds `varlist', has(type numeric) 
				else ds `varlist', has(type string) 
				local varlist `r(varlist)' 
				if "`varlist'" == "" { 
					di as err "no variables specified" 
					exit 100
				} 

				if "`vartext'" != "" { 
					local vartext "{txt}all `numeric'`string' variables" 
				} 
			}
		} 

		if "`vartext'" == "" local vartext "{res} `varlist'"
	}

	// looking at observations with missings is the point! 
	marksample touse, novarlist

	// # of observations used  
	quietly count if `touse' 
	if r(N) == 0 error 2000 
	local N = r(N) 
	return scalar N = r(N)
	
	// nmissing is count of missings on variables specified 
	tempvar nmissing  
 
	// basic counts of missing values 
	quietly { 
		if "`sysmiss'" != "" local system "system " 
		gen `nmissing' = 0 if `touse'  
		label var `nmissing' "# of `system'missing values" 
		local min `minimum' 
		if "`min'" == "" local min = cond("`cmd'" == "table", 0, 1) 

		foreach v of local varlist { 
			capture confirm numeric variable `v' 
			local sys = (_rc == 0) & ("`sysmiss'" != "") 

			if `sys' count if `v' == . & `touse' 
			else count if missing(`v') & `touse' 
	
			if r(N) >= `min' { 
				local misslist `misslist' `v' 
				if r(N) == `N' { 
					local droplist `droplist' `v' 
				} 
				local nmiss `nmiss' `r(N)' 
				if "`percent'" != "" { 
					local pc = 100 * `r(N)'/`N' 
					local pcmiss `pcmiss' `pc' 
				}
			}

			if `sys' replace `nmissing' = `nmissing' + (`v' == .) if `touse' 
			else replace `nmissing' = `nmissing' + missing(`v') if `touse' 
		}

		// % missing if requested                                   
		if "`percent'" != "" & "`observations'" != "" { 
			local nvars : word count `varlist' 
			tempvar pcmissing 
			gen `pcmissing' = 100 * `nmissing'/`nvars' if `touse'  
			label var `pcmissing' "% of `system'missing values" 
			format `pcmissing' `format' 
 		} 
	}
	
	// show header by default and count of observations with missing values 
	if "`header'" == "" { 
		di _n "{p 0 4}{txt}Checking missings in `vartext':{txt}{p_end}"
	}
	else di   

	quietly count if `nmissing' & `touse'
	local NM = r(N)
	di "`NM' " cond(`NM' == 1, "observation", "observations") ///
	" with `system'missing values" 

	// now actions for each subcommand 
	if "`cmd'" == "report" {
		if `NM' == 0 exit 0 

		if "`observations'" != "" { 
			char `nmissing'[varname] "# `system'missing" 
			if "`percent'" != "" {  
				char `pcmissing'[varname] "% `system'missing" 
			}
			list `identify' `nmissing' `pcmissing' if `nmissing' >= `min', ///
			abbrev(9) subvarname `options' 

			exit 0 
		} 

		tokenize "`nmiss'" 

		// set up matrices in Mata 
		if "`percent'" != "" { 
			mata : results = J(0, 2, .) 
		}
		else mata : results = J(0, 1, .) 
		mata : text = J(0, 1, "")

		local j = 1 
		foreach v of local misslist { 
			mata : text = text \ "`v'" 

			if "`percent'" != "" { 
				local pcm : word `j' of `pcmiss' 
				mata : results = results \ (``j'', `pcm')
			}
			else mata : results = results \ (``j'')
 
			local ++j 
		}

		preserve 
		drop _all

		local nvars : word count `misslist'  
		quietly set obs `nvars' 
		getmata which = text
		getmata results* = results 

		char which[varname] " " 
		char results1[varname] "# missing"
		if "`percent'" != "" { 
			char results2[varname] "% missing"
			format results2 `format'
		}

		if "`sort'`sort2'" != "" {
			if `missing' { 
				if `descending' gsort - results1 
				else sort results1
			}
			else if `alpha' {
				if `descending' gsort - which
				else sort which
			} 

			if "`show'" != "" local inobs "in 1/`show'"
		}

		list `inobs', abbrev(9) subvarname noobs `options' 
	
		mata mata clear 

		return local varlist "`misslist'" 
	}
	else if "`cmd'" == "breakdown" { 
		quietly ds `misslist', has(type string) 
		local strhere = "`r(varlist)'" != "" 
		quietly ds `misslist', has(type numeric) 
		local numhere = "`r(varlist)'" != "" 
		
		quietly if `numhere' { 
			if "`sysmiss'" != "" local levels . 

			else {
				foreach v of local misslist {
					levelsof `v' if missing(`v') & `touse', missing clean local(this) 
					local levels `levels'  `this' 
				} 
				local levels : list uniq levels 
				local levels : list sort levels 
			} 

			local nlevels : list sizeof levels
		} 

		// set up matrices in Mata
		mata : allresults = J(0, 1, .)  
		mata : numresults = J(0, `nlevels', .)
		mata : strresults = J(0, `strhere', .) 
		mata : text = J(0, 1, "") 
 
		quietly foreach v of local misslist { 
			local j = 0 
			
			count if missing(`v') & `touse'
			mata : allresults = allresults \ `r(N)' 
 
                        capture confirm numeric variable `v' 

			if _rc {
				mata : strresults = strresults \ `r(N)' 
				if `numhere' mata : numresults = numresults \ J(1, `nlevels', .)
			}
			else { 
				local counts  
				foreach x of local levels {
					local ++j 
					count if `v' == `x' & `touse'
					local counts `counts' `r(N)' 
				}

				local counts : subinstr local counts " " ",", all   
				mata : numresults = numresults \ (`counts') 
				if `strhere' mata : strresults = strresults \ . 
			}

			mata : text = text \ ("`v'") 
		} 
	
		preserve 
		drop _all

		local nvars : word count `misslist'  
		quietly set obs `nvars' 

		getmata which = text
		char which[varname] " " 
 	
		getmata allcount = allresults 
		char allcount[varname] "# missing"

		if `strhere' { 
			getmata strcount = strresults 
			char strcount[varname] "empty" 
		} 

		if `numhere' {
			getmata numcount* = numresults 

			tokenize "`levels'" 
			forval j = 1/`nlevels' { 
				char numcount`j'[varname] "``j''"
			} 
		}
		
		if "`sort'`sort2'" != "" {
			if `missing' { 
				if `descending' gsort - allcount  
				else sort allcount 
			}
			else if `alpha' {
				if `descending' gsort - which
				else sort which
			} 

			if "`show'" != "" local inobs "in 1/`show'"
		}

		list `inobs', abbrev(9) subvarname noobs `options' 
	
		mata mata clear 

		return local varlist "`misslist'" 
	} 
	else if "`cmd'" == "list" {
		if `NM' > 0 {
			local show : list identify | misslist 
			local show : list uniq show
			list `show' if `nmissing' >= `min' & `touse', `options'
		}
		return local varlist "`misslist'" 
	}
	else if "`cmd'" == "table" {
		if `NM' > 0 {
			local cond `nmissing' >= `min' & `touse'

			local nid : word count `identify' 
			if `nid' == 0  { 
				tab `nmissing' if `cond', `options' 
			}  				
			else if `nid' == 1  {
				qui tab `identify' if `cond' 
				local I = r(r) 
				qui tab `nmissing' if `cond' 
				local J = r(r) 

				if `J' <= `I' tab `identify' `nmissing' if `cond', `options'
				else tab `nmissing' `identify' if `cond', `options' 
			}  				
			else error 103 
		}
		return local varlist "`misslist'" 
	}
	else if "`cmd'" == "tag" { 
		gen double `generate' = `nmissing' if `touse' 
		quietly compress `generate' 
	} 	
	else if "`cmd'" == "dropvars" {
		di
		if "`droplist'" != "" { 
			noisily drop `droplist' 
			di "{p}note: `droplist' dropped{p_end}" 
		}
		else di "note: no variables qualify" 
		return local varlist "`droplist'" 
	}
	else if "`cmd'" == "dropobs" { 
		di 
		local nvars : word count `varlist' 
		quietly count if `nmissing' == `nvars' & `touse' 
		return scalar n_dropped = r(N) 
		
		if r(N) == 0 di "note: no observations qualify" 
		else noisily { 
			drop if `nmissing' == `nvars' & `touse' 
		}
	} 
end

