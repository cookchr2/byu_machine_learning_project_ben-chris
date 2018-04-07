 
set more off, perm
cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg

local states = "New_York_part1 New_York_part2 North_Carolina North_Dakota Ohio Oregon"

foreach state in `states' {
	use pot_`state'_`state', clear
	 
	merge m:1 ark1900 using R:\JoePriceResearch\record_linking\data\census_1900\census1900_raw\data\state_files\\`state'.dta
	keep if _merge == 3
	drop _merge
		
	rename pr_name_gn poi_name_gn1900
	rename pr_birth_year poi_birthyear1900
	rename pr_name_surn poi_name_surn1900
	rename pr_marital_status marital1900
	rename pr_relationship_to_head relhead1900
	rename event_township township1900
	rename event_county county1900
	rename event_state state1900
		
	drop event_place

	merge m:1 ark1910 using R:\JoePriceResearch\record_linking\data\census_1910\data\state_files\\`state'.dta
	keep if _merge == 3
	drop _merge

	rename pr_name_gn poi_name_gn1910
	rename pr_bir_year poi_birthyear1910
	rename pr_name_surn poi_name_surn1910
	rename pr_marital_status marital1910
	rename pr_relationship_code relhead1910
	rename event_township township1910
	**** Get the country, state, county, and city for each observation ****
	* Make a copy of event_place to work with *
	gen temp = reverse(event_place)

	* Get the various pieces *
	split temp, p(",")
	forval x = 1/`r(nvars)'{
		replace temp`x' = trim(reverse(temp`x'))
	}

	* Rename the variables *
	ren (temp1 temp2 temp3) (country1910 state1910 county1910)




	gen pr_name_gn = poi_name_gn1900
	merge m:1 pr_name_gn using R:\JoePriceResearch\record_linking\data\census_1910\data\obj\names_crosswalk.dta
	drop if _merge == 2
	rename tot poi_name_freq1900
	replace pr_name_gn = poi_name_gn1910
	drop _merge
	merge m:1 pr_name_gn using R:\JoePriceResearch\record_linking\data\census_1910\data\obj\names_crosswalk.dta
	drop if _merge == 2
	drop _merge
	rename tot poi_name_freq1910
	drop pr_name_gn


	gen names = poi_name_surn1900
	merge m:1 names using R:\JoePriceResearch\record_linking\data\census_1910\data\obj\last_names_crosswalk.dta
	drop if _merge == 2
	rename _0 poi_surn_freq1900
	replace names = poi_name_surn1910
	drop _merge
	merge m:1 names using R:\JoePriceResearch\record_linking\data\census_1910\data\obj\last_names_crosswalk.dta
	drop if _merge == 2
	drop _merge
	rename _0 poi_surn_freq1910
	drop names

	replace poi_name_freq1900 = 0 if poi_name_freq1900 == .
	replace poi_name_freq1910 = 0 if poi_name_freq1910 == .
	replace poi_surn_freq1900 = 0 if poi_surn_freq1900 == .
	replace poi_surn_freq1910 = 0 if poi_surn_freq1910 == .

	destring poi_birthyear1900, replace

	replace poi_name_freq1900 = 0 if poi_name_freq1900 == .
	replace poi_name_freq1910 = 0 if poi_name_freq1910 == .
	replace poi_surn_freq1900 = 0 if poi_surn_freq1900 == .
	replace poi_surn_freq1910 = 0 if poi_surn_freq1910 == .

	************ PARSING OUT TOWNSHIP EXACTLY AS TANNER DID
	**** Clean the city variable ****
	* Get rid of precincts, townships, wards, and districts with their associated numbers *
	replace township1900 = regexr(township1900," +"," ")
	replace township1900 = regexr(township1900," ?(Precincts?|Wards?|Districts?|Townships?) ?([0-9]?[0-9]?)-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?","")

	* Clean out anything with parentheses *
	replace township1900 = regexr(township1900,"\(.*\).*","")

	* Get only the main city *
	replace township1900 = regexr(township1900,",.*","")

	* Get rid of "city", "town", and village *
	replace township1900 = regexr(township1900," city| town| village| township","")
	replace township1900 = trim(township1900)

	* Get rid of "and" or "or" *
	replace township1900 = regexr(township1900," +"," ")
	replace township1900 = regexr(township1900,"( and | or ).*","")

	* Clean odd things *
	replace township1900 = subinstr(township1900,".*&amp;","",.)
	replace township1900 = trim(regexr(township1900,"/?[0-9]+",""))

	* Fix duplicate city names *
	replace township1900 = regexr(township1900," +"," ")
	replace township1900 = regexr(township1900," ?(Precincts?|Wards?|Districts?|Townships?) ?([0-9]?[0-9]?)-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?","")
	split township1900, p(" ")
	replace township1900 = ""

	* We will just assume that city names are two words long, Google will catch those *
	replace township1900 = township19001
	replace township1900 = township1900 + " " + township19002 if township19001 != township19002 & township19002 != ""

	*1910
	**** Clean the city variable ****
	* Get rid of precincts, townships, wards, and districts with their associated numbers *
	replace township1910 = regexr(township1910," +"," ")
	replace township1910 = regexr(township1910," ?(Precincts?|Wards?|Districts?|Townships?) ?([0-9]?[0-9]?)-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?","")

	* Clean out anything with parentheses *
	replace township1910 = regexr(township1910,"\(.*\).*","")

	* Get only the main city *
	replace township1910 = regexr(township1910,",.*","")

	* Get rid of "city", "town", and village *
	replace township1910 = regexr(township1910," city| town| village| township","")
	replace township1910 = trim(township1910)

	* Get rid of "and" or "or" *
	replace township1910 = regexr(township1910," +"," ")
	replace township1910 = regexr(township1910,"( and | or ).*","")

	* Clean odd things *
	replace township1910 = subinstr(township1910,".*&amp;","",.)
	replace township1910 = trim(regexr(township1910,"/?[0-9]+",""))

	* Fix duplicate city names *
	replace township1910 = regexr(township1910," +"," ")
	replace township1910 = regexr(township1910," ?(Precincts?|Wards?|Districts?|Townships?) ?([0-9]?[0-9]?)-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?","")
	split township1910, p(" ")
	replace township1910 = ""

	* We will just assume that city names are two words long, Google will catch those *
	replace township1910 = township19101
	replace township1910 = township1910 + " " + township19102 if township19101 != township19102 & township19102 != ""compress

	*********************** GETTING Lat and LON

	rename township1900 city
	rename state1900 state
	rename county1900 county

	joinby city state county using "R:\JoePriceResearch\record_linking\projects\german_discrimination\data\towns\cw1900_chris.dta", unm(m)

	duplicates drop city state county ark1900 ark1910, force
	rename lat lat1900
	rename lon lon1900
	rename city township1900 
	rename state state1900 
	rename county county1900 

	*1910

	rename township1910 city
	rename state1910 state
	rename county1910 county

	drop _merge
	joinby city state county using "R:\JoePriceResearch\record_linking\projects\german_discrimination\data\towns\cw1910_chris.dta", unm(m)

	duplicates drop city state county ark1900 ark1910, force
	rename lat lat1910
	rename lon lon1910
	rename city township1910 
	rename state state1910 
	rename county county1910 

	geodist lat1900 lon1900 lat1910 lon1910, gen(distance)

	destring poi_birthyear1900, replace
	destring poi_birthyear1910, replace
	gen poi_birthyear = (poi_birthyear1900 + poi_birthyear1910) / 2
	
	save pot_`state'_all_vars, replace

	keep name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
	gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
	midinit_match sex_same namelength1900 namelength1910 same_state same_county /// 
	same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
	uncommon_name1900 uncommon_name1910 common_name1900 common_name1910 ///
	num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 ///
	uncommon_surn1900 uncommon_surn1910 common_surn1900 common_surn1910 ///
	distance poi_name_freq1900 poi_name_freq1910 poi_surn_freq1900 poi_surn_freq1910 ///
	poi_birthyear ark1900 ark1910

	order name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
	gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
	midinit_match sex_same namelength1900 namelength1910 same_state same_county /// 
	same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
	uncommon_name1900 uncommon_name1910 common_name1900 common_name1910 ///
	num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 ///
	uncommon_surn1900 uncommon_surn1910 common_surn1900 common_surn1910 ///
	distance poi_name_freq1900 poi_name_freq1910 poi_surn_freq1900 poi_surn_freq1910 ///
	poi_birthyear ark1900 ark1910

	*Because the classifier can't deal with NaNs we still have to put something in
	foreach v of var * {
		if "`v'" != "ark1900" & "`v'" != "ark1910" {
			replace `v' = -1 if `v' == .
		}
	}

	 
	save pred_ready_`state', replace
}

