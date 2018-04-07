set more off, perm
cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg

local states1900 = "Alabama Arkansas California Colorado Connecticut Delaware District_of_Columbia Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada New_Hampshire New_Jersey New_Mexico New_York_part1 North_Carolina North_Dakota Ohio Oklahoma Oregon Pennsylvania_part1 Pennsylvania_part2 Rhode_Island South_Carolina South_Dakota Tennessee Texas Utah Vermont Virginia Washington West_Virginia Wisconsin Wyoming"
local states1910 = "Alabama Alaska Arizona Arkansas California Colorado Connecticut Delaware District_of_Columbia Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada New_Hampshire New_Jersey New_Mexico New_York_part1 North_Carolina North_Dakota Ohio Oklahoma Oregon Pennsylvania_part1 Pennsylvania_part2 Rhode_Island South_Carolina South_Dakota Tennessee Texas Utah Vermont Virginia Washington West_Virginia Wisconsin Wyoming"

local year1 = 1900
local year2 = 1910

foreach state in `states1900' {
	foreach state1 in `states1910' { 
		if (regexm("`state1'",regexr("`state'", "_part[12]", ""))) {
			use R:\JoePriceResearch\record_linking\data\census_1910\data\state_files\\`state1', clear
			
			*We need to find the missing place information, and if it's missing put it in
			split event_place, p(",")
			if "`r(nvars)'" == "5" {
				replace event_place1 = event_place1 + "," + event_place2 if event_place5 != ""
				replace event_place2 = event_place3 if event_place5 != ""
				replace event_place3 = event_place4 if event_place5 != ""
				replace event_place4 = event_place5 if event_place5 != ""
				drop event_place5
			}

			*annoyingly, this information varies across state. So what I've done is 
			*rename the variables if they don't exist
			capture confirm variable event_township
			if _rc {
			rename event_place1 event_township
			replace event_township = strtrim(event_township)
			}
			capture confirm variable event_county 
			if _rc {
			rename event_place2 event_county
			replace event_county = strtrim(event_county)
			}
			capture confirm variable event_state
			if _rc {		
			rename event_place3 event_state
			replace event_state = strtrim(event_state)
			}
			capture confirm variable event_country
			if _rc {		
			rename event_place4 event_country
			replace event_country = strtrim(event_country)
			}
			drop event_place
			
			append using R:\JoePriceResearch\record_linking\data\census_1900\census1900_raw\data\state_files\\`state'

			
			*The above code may be generalized for other states, but is not required for 1900
			
			*rename variables into what we want at the end. This part will have to be 
			*tailored to your year.
			rename event_township township
			rename event_county county
			rename event_state state 
			rename pr_name_gn poi_name_gn
			rename pr_name_surn poi_name_surn

			destring pr_age, replace

			gen poi_birthyear = `year1' - pr_age if ark`year1' != ""
			replace poi_birthyear = `year2' - pr_age if ark`year2' != ""

			gen poi_birthplace = pr_birth_place if ark`year1' != ""
			replace poi_birthplace = pr_bir_place if ark`year2' != ""
			gen poi_mbpl = pr_mthr_birth_place if ark`year1' != ""
			replace poi_mbpl = pr_mthr_bir_place if ark`year2' != ""
			gen poi_fbpl = pr_fthr_birth_place if ark`year1' != ""
			replace poi_fbpl = pr_fthr_bir_place if ark`year2' != ""

			rename pr_sex_code poi_sex
			rename pr_race_or_color poi_race

			gen poi_imm_yr = pr_immigration_year if ark`year1' != ""
			replace poi_imm_yr = pr_imm_year if ark`year2' != ""

			keep ark`year1' ark`year2' township county state poi_name_gn ///
			poi_name_surn poi_birthyear poi_birthplace poi_mbpl ///
			poi_fbpl poi_sex poi_race poi_imm_yr 

			*Now I'm going to bin our data

			destring poi_birthyear, replace

			gen birth_bin = round(poi_birthyear, 5)
			gen gn_stub = substr(poi_name_gn, 1, 2)
			egen close_name_gn = group(gn_stub)

			gen surn_stub = substr(poi_name_surn, 1, 2)
			egen close_name_surn = group(surn_stub)

			*This part is up for debate. I hate to include county, but with birthplace removed
			*I needed to balance the data.
			egen bin = group(birth_bin close_name_gn surn_stub poi_sex county)

			/*
			save temp1, replace
			use temp1, clear
			*/


			**Next, we're only going to match across DIFFERENT censuses 
			gen bin_copy = bin

			replace bin = . if ark`year1' == ""
			replace bin_copy = . if ark`year2' == ""

			drop birth_bin-close_name_surn
			compress

			save temp, replace

			foreach v of var * {
				if "`v'" != "ark`year1'" & "`v'" != "ark`year2'" {
					rename `v' `v'`year2'
				}
			}

			drop bin1
			rename bin_copy1 bin
			drop if bin == .
			save temp2, replace

			use temp, clear
			drop if bin == .
			drop ark`year2'
			foreach v of var * {
				if "`v'" != "ark`year1'" & "`v'" != "ark`year2'" {
					rename `v' `v'`year1'
				}
			}
			rename bin`year1' bin
			joinby bin using temp2 //Yeah this line can totally destroy you :)
			drop bin_copy`year1' 


			********************************************************************************
			********************************************************************************
			********************************************************************************

			*This line only keeps germans
			keep if poi_birthplace`year1' == "Germany" | poi_birthplace`year2' == "Germany"
			

			gen pr_name_gn = poi_name_gn`year1'
			merge m:1 pr_name_gn using R:\JoePriceResearch\record_linking\data\census_1910\data\obj\names_crosswalk.dta
			drop if _merge == 2
			rename tot poi_name_freq`year1'
			replace pr_name_gn = poi_name_gn`year2'
			drop _merge
			merge m:1 pr_name_gn using R:\JoePriceResearch\record_linking\data\census_1910\data\obj\names_crosswalk.dta
			drop if _merge == 2
			drop _merge
			rename tot poi_name_freq`year2'
			drop pr_name_gn


			gen names = poi_name_surn`year1'
			merge m:1 names using R:\JoePriceResearch\record_linking\data\census_1910\data\obj\last_names_crosswalk.dta
			drop if _merge == 2
			rename _0 poi_surn_freq`year1'
			replace names = poi_name_surn`year2'
			drop _merge
			merge m:1 names using R:\JoePriceResearch\record_linking\data\census_1910\data\obj\last_names_crosswalk.dta
			drop if _merge == 2
			drop _merge
			rename _0 poi_surn_freq`year2'
			drop names

			replace poi_name_freq`year1' = 0 if poi_name_freq`year1' == .
			replace poi_name_freq`year2' = 0 if poi_name_freq`year2' == .
			replace poi_surn_freq`year1' = 0 if poi_surn_freq`year1' == .
			replace poi_surn_freq`year2' = 0 if poi_surn_freq`year2' == .

			destring poi_birthyear`year1', replace

			replace poi_name_freq`year1' = 0 if poi_name_freq`year1' == .
			replace poi_name_freq`year2' = 0 if poi_name_freq`year2' == .
			replace poi_surn_freq`year1' = 0 if poi_surn_freq`year1' == .
			replace poi_surn_freq`year2' = 0 if poi_surn_freq`year2' == .

			************ PARSING OUT TOWNSHIP EXACTLY AS TANNER DID
			**** Clean the city variable ****
			* Get rid of precincts, townships, wards, and districts with their associated numbers *
			replace township`year1' = regexr(township`year1'," +"," ")
			replace township`year1' = regexr(township`year1'," ?(Precincts?|Wards?|Districts?|Townships?) ?([0-9]?[0-9]?)-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?","")

			* Clean out anything with parentheses *
			replace township`year1' = regexr(township`year1',"\(.*\).*","")

			* Get only the main city *
			replace township`year1' = regexr(township`year1',",.*","")

			* Get rid of "city", "town", and village *
			replace township`year1' = regexr(township`year1'," city| town| village| township","")
			replace township`year1' = trim(township`year1')

			* Get rid of "and" or "or" *
			replace township`year1' = regexr(township`year1'," +"," ")
			replace township`year1' = regexr(township`year1',"( and | or ).*","")

			* Clean odd things *
			replace township`year1' = subinstr(township`year1',".*&amp;","",.)
			replace township`year1' = trim(regexr(township`year1',"/?[0-9]+",""))

			* Fix duplicate city names *
			replace township`year1' = regexr(township`year1'," +"," ")
			replace township`year1' = regexr(township`year1'," ?(Precincts?|Wards?|Districts?|Townships?) ?([0-9]?[0-9]?)-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?","")
			split township`year1', p(" ")
			replace township`year1' = ""

			* We will just assume that city names are two words long, Google will catch those *
			replace township`year1' = township`year1'1
			replace township`year1' = township`year1' + " " + township`year1'2 if township`year1'1 != township`year1'2 & township`year1'2 != ""

			*1910
			**** Clean the city variable ****
			* Get rid of precincts, townships, wards, and districts with their associated numbers *
			replace township`year2' = regexr(township`year2'," +"," ")
			replace township`year2' = regexr(township`year2'," ?(Precincts?|Wards?|Districts?|Townships?) ?([0-9]?[0-9]?)-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?","")

			* Clean out anything with parentheses *
			replace township`year2' = regexr(township`year2',"\(.*\).*","")

			* Get only the main city *
			replace township`year2' = regexr(township`year2',",.*","")

			* Get rid of "city", "town", and village *
			replace township`year2' = regexr(township`year2'," city| town| village| township","")
			replace township`year2' = trim(township`year2')

			* Get rid of "and" or "or" *
			replace township`year2' = regexr(township`year2'," +"," ")
			replace township`year2' = regexr(township`year2',"( and | or ).*","")

			* Clean odd things *
			replace township`year2' = subinstr(township`year2',".*&amp;","",.)
			replace township`year2' = trim(regexr(township`year2',"/?[0-9]+",""))

			* Fix duplicate city names *
			replace township`year2' = regexr(township`year2'," +"," ")
			replace township`year2' = regexr(township`year2'," ?(Precincts?|Wards?|Districts?|Townships?) ?([0-9]?[0-9]?)-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?-?,? ?[0-9]?[0-9]?","")
			split township`year2', p(" ")
			replace township`year2' = ""

			* We will just assume that city names are two words long, Google will catch those *
			replace township`year2' = township`year2'1
			replace township`year2' = township`year2' + " " + township`year2'2 if township`year2'1 != township`year2'2 & township`year2'2 != ""compress

			*********************** GETTING Lat and LON

			rename township`year1' city
			rename state`year1' state
			rename county`year1' county

			joinby city state county using "R:\JoePriceResearch\record_linking\projects\german_discrimination\data\towns\cw`year1'_chris.dta", unm(m)

			duplicates drop city state county ark`year1' ark`year2', force
			rename lat lat`year1'
			rename lon lon`year1'
			rename city township`year1'
			rename state state`year1'
			rename county county`year1'

			*1910

			rename township`year2' city
			rename state`year2' state
			rename county`year2' county

			drop _merge
			joinby city state county using "R:\JoePriceResearch\record_linking\projects\german_discrimination\data\towns\cw`year2'_chris.dta", unm(m)

			duplicates drop city state county ark`year1' ark`year2', force
			rename lat lat`year2'
			rename lon lon`year2'
			rename city township`year2' 
			rename state state`year2' 
			rename county county`year2' 

			geodist lat`year1' lon`year1' lat`year2' lon`year2', gen(distance)

			destring poi_birthyear`year1', replace
			destring poi_birthyear`year2', replace
			gen poi_birthyear = (poi_birthyear`year1' + poi_birthyear`year2') / 2

			** create some features based on the given name and lastname
			for X in any `year1' `year2': rename poi_name_gnX gnameX
			for X in any `year1' `year2': rename poi_name_surnX lnameX

			foreach Z in gname lname {
				foreach X in `year1' `year2'  {
					replace `Z'`X' = lower(trim(`Z'`X')) 
				}
				foreach X in `year1' `year2' {
					replace `Z'`X' = trim(`Z'`X') 
				}
				gen `Z'_length = abs(length(`Z'`year1') - length(`Z'`year2'))
				jarowinkler `Z'`year1' `Z'`year2', generate(`Z'_jaro) 
				gen `Z'_same = `Z'`year1'==`Z'`year2'
				gen `Z'_firstl = substr(`Z'`year1',1,1)==substr(`Z'`year2',1,1)
				gen `Z'_lastl = substr(`Z'`year1',-1,1)==substr(`Z'`year2',-1,1)
				gen `Z'_soundex = soundex(`Z'`year1') == soundex(`Z'`year2')
				}

			gen name_same = gname`year1'==gname`year2' & lname`year1'==lname`year2'

			gen diff_birthyear = abs(poi_birthyear`year1' - poi_birthyear`year2')
			gen birthyr_abs1 = 1 == diff_birthyear
			gen birthyr_abs2 = 2 == diff_birthyear
			gen birthyr_abs3 = 3 == diff_birthyear
			gen birthyr_same = 0 == diff_birthyear

			** check about middle initial (convert thses lines into a single regular expression)
			foreach X in `year1' `year2' {
				split gname`X'
			}
			foreach X in `year1' `year2' {
				gen midinit`X' = substr(gname`X'2,1,1) 
			}
			gen midinit_match = midinit`year1' == midinit`year2'
			replace midinit_match = 0 if midinit`year1' == ""

			gen sex_same = 0
			replace sex_same = 1 if poi_sex`year1' == poi_sex`year2'

			*namelength

			gen namelength`year1' = strlen(gname`year1' + lname`year1')
			gen namelength`year2' = strlen(gname`year2' + lname`year2')

			*Distance

			*Same State
			gen same_state = 0
			replace state`year2' = strtrim(state`year2')
			replace state`year1' = strtrim(state`year1')
			replace county`year2' = strtrim(county`year2')
			replace county`year1' = strtrim(county`year1')
			replace same_state = 1 if state`year1' == state`year2'
			replace same_state = 0 if state`year1' == ""

			*Same county
			gen same_county = 0
			replace same_county = 1 if county`year1' == county`year2'
			replace same_county = 0 if county`year1' == ""


			*Same Township

			gen same_township = 0
			replace same_township = 1 if township`year1' == township`year2'
			replace same_township = 0 if township`year1' == ""

			jarowinkler township`year1' township`year2', generate(township_jaro) 


			*Same race

			gen same_race = 0
			replace same_race = 1 if poi_race`year1' == poi_race`year2' & poi_race`year1' != ""

			*Race dist

			gen race_dist = 2
			replace race_dist = 0 if poi_race`year1' == poi_race`year2' & poi_race`year1' != ""
			replace race_dist = 1 if poi_race`year1' == "Black" & poi_race`year2' == "Mulatto"
			replace race_dist = 1 if poi_race`year1' == "Mulatto" & poi_race`year2' == "Black"
			replace race_dist = 1 if poi_race`year1' == "White" & poi_race`year2' == "Mulatto"
			replace race_dist = 1 if poi_race`year1' == "Mulatto" & poi_race`year2' == "White"

			* same bpl
			gen same_bpl = 0
			replace same_bpl = 1 if poi_birthplace`year1' == poi_birthplace`year2' & poi_birthplace`year1' != ""

			*dist bpl

			*mpbl fbpl, (dist)
			gen same_mbpl = 0
			replace same_mbpl = 1 if poi_mbpl`year1' == poi_mbpl`year2' & poi_mbpl`year1' != ""

			gen same_fbpl = 0
			replace same_fbpl = 1 if poi_fbpl`year1' == poi_fbpl`year2' & poi_fbpl`year1' != ""


			*imm yr

			gen same_imm_yr = 0
			destring poi_imm_yr`year1', replace
			destring poi_imm_yr`year2', replace
			replace same_imm_yr = 1 if poi_imm_yr`year1' == poi_imm_yr`year2' & poi_imm_yr`year1' != .

			*Uncommon and common names
			gen uncommon_name`year1' = 0
			replace uncommon_name`year1' = 1 if poi_name_freq`year1' <= 20

			gen uncommon_name`year2' = 0
			replace uncommon_name`year2' = 1 if poi_name_freq`year2' <= 20

			gen common_name`year1' = 0
			replace common_name`year1' = 1 if poi_name_freq`year1' >= 1000000

			gen common_name`year2' = 0
			replace common_name`year2' = 1 if poi_name_freq`year2' >= 1000000

			gen uncommon_surn`year1' = 0
			replace uncommon_surn`year1' = 1 if poi_surn_freq`year1' <= 20

			gen uncommon_surn`year2' = 0
			replace uncommon_surn`year2' = 1 if poi_surn_freq`year2' <= 20

			gen common_surn`year1' = 0
			replace common_surn`year1' = 1 if poi_surn_freq`year1' >= 1000000

			gen common_surn`year2' = 0
			replace common_surn`year2' = 1 if poi_surn_freq`year2' >= 1000000

			* #of names

			split lname`year1'
			
			if "`r(nvars)'" == "1" {
				gen lname`year1'2 = ""
			}
			
			split lname`year2'
			if "`r(nvars)'" == "1" {
				gen lname`year2'2 = ""
			}		
			

			gen num_names`year1' = 0
			replace num_names`year1' = num_names`year1' + 1 if gname`year1'1 != ""
			replace num_names`year1' = num_names`year1' + 1 if gname`year1'2 != ""

			replace num_names`year1' = num_names`year1' + 1 if lname`year1'1 != ""
			replace num_names`year1' = num_names`year1' + 1 if lname`year1'2 != ""

			gen num_names`year2' = 0
			replace num_names`year2' = num_names`year2' + 1 if gname`year2'1 != ""
			replace num_names`year2' = num_names`year2' + 1 if gname`year2'2 != ""

			replace num_names`year2' = num_names`year2' + 1 if lname`year2'1 != ""
			replace num_names`year2' = num_names`year2' + 1 if lname`year2'2 != ""


			* Max JW

			jarowinkler gname`year1'1 gname`year2'1, generate(n1) 
			jarowinkler gname`year1'1 gname`year2'2, generate(n2) 
			jarowinkler gname`year1'1 lname`year2'1, generate(n4) 
			jarowinkler gname`year1'1 lname`year2'2, generate(n5) 

			jarowinkler gname`year1'2 gname`year2'1, generate(n7) 
			jarowinkler gname`year1'2 gname`year2'2, generate(n8) 
			jarowinkler gname`year1'2 lname`year2'1, generate(n10) 
			jarowinkler gname`year1'2 lname`year2'2, generate(n11) 


			jarowinkler lname`year1'1 gname`year2'1, generate(n19) 
			jarowinkler lname`year1'1 gname`year2'2, generate(n20) 
			jarowinkler lname`year1'1 lname`year2'1, generate(n22) 
			jarowinkler lname`year1'1 lname`year2'2, generate(n23) 
			
			
			jarowinkler lname`year1'2 gname`year2'1, generate(n25) 
			jarowinkler lname`year1'2 gname`year2'2, generate(n26) 
			jarowinkler lname`year1'2 lname`year2'1, generate(n28) 
			jarowinkler lname`year1'2 lname`year2'2, generate(n29) 


			replace n1 = . if gname`year1'1 == "" | gname`year2'1 == "" 
			replace n2 = . if gname`year1'1 == "" | gname`year2'2 == "" 
			replace n4 = . if gname`year1'1 == "" |  lname`year2'1 == ""  
			replace n5 = . if gname`year1'1 == "" |  lname`year2'2 == ""  

			replace n7 = . if gname`year1'2 == "" |  gname`year2'1 == "" 
			replace n8 = . if gname`year1'2 == "" |  gname`year2'2 == "" 
			replace n10 = . if gname`year1'2 == "" |  lname`year2'1 == ""  
			replace n11 = . if gname`year1'2 == "" |  lname`year2'2 == ""  


			replace n19 = . if lname`year1'1 == "" |  gname`year2'1 == "" 
			replace n20 = . if lname`year1'1 == "" |  gname`year2'2 == ""  
			replace n22 = . if lname`year1'1 == "" |  lname`year2'1 == ""  
			replace n23 = . if lname`year1'1 == "" |  lname`year2'2 == ""  

			replace n25 = . if lname`year1'2 == "" |  gname`year2'1 == ""  
			replace n26 = . if lname`year1'2 == "" |  gname`year2'2 == ""  
			replace n28 = . if lname`year1'2 == "" |  lname`year2'1 == ""  
			replace n29 = . if lname`year1'2 == "" |  lname`year2'2 == ""  

			egen k1 = rowmax(n1 n2 n4 n5)
			egen k2 = rowmax(n7-n11)
			egen k4 = rowmax(n19-n23)
			egen k5 = rowmax(n25-n29)

			egen j1 = rowmax(n1 n7 n19 n25)
			egen j2 = rowmax(n2 n8 n20 n26)
			egen j4 = rowmax(n4 n10 n22 n28)
			egen j5 = rowmax(n5 n11 n23 n29)

			egen max_jw_gn = rowmax(k1 k2 j1 j2)
			egen max_jw_surn = rowmax(k4 k5 j4 j5)

			* Avg JW

			egen avg_jw_dim1 = rowmean(k1 k2 k4 k5)
			egen avg_jw_dim2 = rowmean(j1 j2 j4 j5)
					
			save germ/pot_`state'_`state1'_all_vars_germ, replace

			keep name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
			gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
			midinit_match sex_same namelength`year1' namelength`year2' same_state same_county /// 
			same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
			uncommon_name`year1' uncommon_name`year2' common_name`year1' common_name`year2' ///
			num_names`year1' num_names`year2' max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 ///
			uncommon_surn`year1' uncommon_surn`year2' common_surn`year1' common_surn`year2' ///
			distance poi_name_freq`year1' poi_name_freq`year2' poi_surn_freq`year1' poi_surn_freq`year2' ///
			poi_birthyear ark`year1' ark`year2'

			order name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
			gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
			midinit_match sex_same namelength`year1' namelength`year2' same_state same_county /// 
			same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
			uncommon_name`year1' uncommon_name`year2' common_name`year1' common_name`year2' ///
			num_names`year1' num_names`year2' max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 ///
			uncommon_surn`year1' uncommon_surn`year2' common_surn`year1' common_surn`year2' ///
			distance poi_name_freq`year1' poi_name_freq`year2' poi_surn_freq`year1' poi_surn_freq`year2' ///
			poi_birthyear ark`year1' ark`year2'
			
			foreach v of var * {
				if "`v'" != "ark`year1'" & "`v'" != "ark`year2'" {
					replace `v' = -1 if `v' == .
				}
			}


			save germ/pot_`state'_`state1'_germ, replace
		}
	}		
}

	
