cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg

local states = "Indiana1 Maryland Massachusetts New_York_part11 Pennsylvania_part1 Pennsylvania_part2"

foreach state in `states' {
	foreach name in `state' `state'1 {
		cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg

		use `name', clear

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


		*create freq feature
		gen freq = poi_name_freq1900 + poi_name_freq1910
		gen surn_freq = poi_surn_freq1900 + poi_surn_freq1910

		** create some features based on the given name and lastname
		for X in any 1900 1910: rename poi_name_gnX gnameX
		for X in any 1900 1910: rename poi_name_surnX lnameX

		foreach Z in gname lname {
			foreach X in 1900 1910  {
				replace `Z'`X' = lower(trim(`Z'`X')) 
			}
			foreach X in 1900 1910 {
				replace `Z'`X' = trim(`Z'`X') 
			}
			gen `Z'_length = abs(length(`Z'1900) - length(`Z'1910))
			jarowinkler `Z'1900 `Z'1910, generate(`Z'_jaro) 
			gen `Z'_same = `Z'1900==`Z'1910
			gen `Z'_firstl = substr(`Z'1900,1,1)==substr(`Z'1910,1,1)
			gen `Z'_lastl = substr(`Z'1900,-1,1)==substr(`Z'1910,-1,1)
			gen `Z'_soundex = soundex(`Z'1900) == soundex(`Z'1910)
			}

		gen name_same = gname1900==gname1910 & lname1900==lname1910

		gen diff_birthyear = abs(poi_birthyear1900 - poi_birthyear1910)
		gen birthyr_abs1 = 1 == diff_birthyear
		gen birthyr_abs2 = 2 == diff_birthyear
		gen birthyr_abs3 = 3 == diff_birthyear
		gen birthyr_same = 0 == diff_birthyear

		** check about middle initial (convert thses lines into a single regular expression)
		foreach X in 1900 1910 {
			split gname`X'
		}
		foreach X in 1900 1910 {
			gen midinit`X' = substr(gname`X'2,1,1) 
		}
		gen midinit_match = midinit1900 == midinit1910
		replace midinit_match = 0 if midinit1900 == ""

		gen sex_same = 0
		replace sex_same = 1 if poi_sex1900 == poi_sex1910

		*namelength

		gen namelength1900 = strlen(gname1900 + lname1900)
		gen namelength1910 = strlen(gname1910 + lname1910)

		*Distance

		*Same State
		gen same_state = 0
		replace state1910 = strtrim(state1910)
		replace state1900 = strtrim(state1900)
		replace county1910 = strtrim(county1910)
		replace county1900 = strtrim(county1900)
		replace same_state = 1 if state1900 == state1910
		replace same_state = 0 if state1900 == ""

		*Same county
		gen same_county = 0
		replace same_county = 1 if county1900 == county1910
		replace same_county = 0 if county1900 == ""


		*Same Township

		gen same_township = 0
		replace same_township = 1 if township1900 == township1910
		replace same_township = 0 if township1900 == ""

		jarowinkler township1900 township1910, generate(township_jaro) 


		*Same race

		gen same_race = 0
		replace same_race = 1 if poi_race1900 == poi_race1910 & poi_race1900 != ""

		*Race dist

		gen race_dist = 2
		replace race_dist = 0 if poi_race1900 == poi_race1910 & poi_race1900 != ""
		replace race_dist = 1 if poi_race1900 == "Black" & poi_race1910 == "Mulatto"
		replace race_dist = 1 if poi_race1900 == "Mulatto" & poi_race1910 == "Black"
		replace race_dist = 1 if poi_race1900 == "White" & poi_race1910 == "Mulatto"
		replace race_dist = 1 if poi_race1900 == "Mulatto" & poi_race1910 == "White"

		* same bpl
		gen same_bpl = 0
		replace same_bpl = 1 if poi_birthplace1900 == poi_birthplace1910 & poi_birthplace1900 != ""

		*dist bpl

		*mpbl fbpl, (dist)
		gen same_mbpl = 0
		replace same_mbpl = 1 if poi_mbpl1900 == poi_mbpl1910 & poi_mbpl1900 != ""

		gen same_fbpl = 0
		replace same_fbpl = 1 if poi_fbpl1900 == poi_fbpl1910 & poi_fbpl1900 != ""


		*imm yr

		gen same_imm_yr = 0
		destring poi_imm_yr1900, replace
		destring poi_imm_yr1910, replace
		replace same_imm_yr = 1 if poi_imm_yr1900 == poi_imm_yr1910 & poi_imm_yr1900 != .

		*Uncommon and common names
		gen uncommon_name1900 = 0
		replace uncommon_name1900 = 1 if poi_name_freq1900 <= 20

		gen uncommon_name1910 = 0
		replace uncommon_name1910 = 1 if poi_name_freq1910 <= 20

		gen common_name1900 = 0
		replace common_name1900 = 1 if poi_name_freq1900 >= 1000000

		gen common_name1910 = 0
		replace common_name1910 = 1 if poi_name_freq1910 >= 1000000

		gen uncommon_surn1900 = 0
		replace uncommon_surn1900 = 1 if poi_surn_freq1900 <= 20

		gen uncommon_surn1910 = 0
		replace uncommon_surn1910 = 1 if poi_surn_freq1910 <= 20

		gen common_surn1900 = 0
		replace common_surn1900 = 1 if poi_surn_freq1900 >= 1000000

		gen common_surn1910 = 0
		replace common_surn1910 = 1 if poi_surn_freq1910 >= 1000000

		* #of names

		split lname1900

		if "`r(nvars)'" == "1" {
			gen lname19002 = ""
		}

		split lname1910
		if "`r(nvars)'" == "1" {
			gen lname19102 = ""
		}		


		gen num_names1900 = 0
		replace num_names1900 = num_names1900 + 1 if gname19001 != ""
		replace num_names1900 = num_names1900 + 1 if gname19002 != ""

		replace num_names1900 = num_names1900 + 1 if lname19001 != ""
		replace num_names1900 = num_names1900 + 1 if lname19002 != ""

		gen num_names1910 = 0
		replace num_names1910 = num_names1910 + 1 if gname19101 != ""
		replace num_names1910 = num_names1910 + 1 if gname19102 != ""

		replace num_names1910 = num_names1910 + 1 if lname19101 != ""
		replace num_names1910 = num_names1910 + 1 if lname19102 != ""


		* Max JW

		jarowinkler gname19001 gname19101, generate(n1) 
		jarowinkler gname19001 gname19102, generate(n2) 
		jarowinkler gname19001 lname19101, generate(n4) 
		jarowinkler gname19001 lname19102, generate(n5) 

		jarowinkler gname19002 gname19101, generate(n7) 
		jarowinkler gname19002 gname19102, generate(n8) 
		jarowinkler gname19002 lname19101, generate(n10) 
		jarowinkler gname19002 lname19102, generate(n11) 


		jarowinkler lname19001 gname19101, generate(n19) 
		jarowinkler lname19001 gname19102, generate(n20) 
		jarowinkler lname19001 lname19101, generate(n22) 
		jarowinkler lname19001 lname19102, generate(n23) 


		jarowinkler lname19002 gname19101, generate(n25) 
		jarowinkler lname19002 gname19102, generate(n26) 
		jarowinkler lname19002 lname19101, generate(n28) 
		jarowinkler lname19002 lname19102, generate(n29) 


		replace n1 = . if gname19001 == "" | gname19101 == "" 
		replace n2 = . if gname19001 == "" | gname19102 == "" 
		replace n4 = . if gname19001 == "" |  lname19101 == ""  
		replace n5 = . if gname19001 == "" |  lname19102 == ""  

		replace n7 = . if gname19002 == "" |  gname19101 == "" 
		replace n8 = . if gname19002 == "" |  gname19102 == "" 
		replace n10 = . if gname19002 == "" |  lname19101 == ""  
		replace n11 = . if gname19002 == "" |  lname19102 == ""  


		replace n19 = . if lname19001 == "" |  gname19101 == "" 
		replace n20 = . if lname19001 == "" |  gname19102 == ""  
		replace n22 = . if lname19001 == "" |  lname19101 == ""  
		replace n23 = . if lname19001 == "" |  lname19102 == ""  

		replace n25 = . if lname19002 == "" |  gname19101 == ""  
		replace n26 = . if lname19002 == "" |  gname19102 == ""  
		replace n28 = . if lname19002 == "" |  lname19101 == ""  
		replace n29 = . if lname19002 == "" |  lname19102 == ""  

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

		cd R:\JoePriceResearch\record_linking\projects\deep_learning\census

		replace poi_name_freq1900 = 0 if poi_name_freq1900 == .
		replace poi_name_freq1910 = 0 if poi_name_freq1910 == .
		replace poi_surn_freq1900 = 0 if poi_surn_freq1900 == .
		replace poi_surn_freq1910 = 0 if poi_surn_freq1910 == .

		replace freq = poi_name_freq1900 + poi_name_freq1910 if freq == .
		replace surn_freq = poi_surn_freq1900 + poi_surn_freq1910 if surn_freq == .

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
		drop township19001-township1900`r(nvars)'

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
		replace township1910 = township1910 + " " + township19102 if township19101 != township19102 & township19102 != ""
		drop township19101-township1910`r(nvars)'
		compress

		*********************** GETTING Lat and LON

		rename township1900 city
		drop state county
		rename state1900 state
		rename county1900 county

		merge m:1 city state county using "R:\JoePriceResearch\record_linking\projects\german_discrimination\data\towns\cw1900_chris.dta"

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
		merge m:1 city state county using "R:\JoePriceResearch\record_linking\projects\german_discrimination\data\towns\cw1910_chris.dta"

		duplicates drop city state county ark1900 ark1910, force
		rename lat lat1910
		rename lon lon1910
		rename city township1910 
		rename state state1910 
		rename county county1910 
		
		drop if ark1900 == ""

		geodist lat1900 lon1900 lat1910 lon1910, gen(distance)

		save `name'_scored_allvarsT2, replace



		keep true name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
		gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
		midinit_match sex_same namelength1900 namelength1910 same_state same_county /// 
		same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
		uncommon_name1900 uncommon_name1910 common_name1900 common_name1910 ///
		num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 ///
		uncommon_surn1900 uncommon_surn1910 common_surn1900 common_surn1910 ///
		distance poi_name_freq1900 poi_name_freq1910 poi_surn_freq1900 poi_surn_freq1910 ///
		poi_birthyear

				
				
		order true name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
		gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
		midinit_match sex_same namelength1900 namelength1910 same_state same_county /// 
		same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
		uncommon_name1900 uncommon_name1910 common_name1900 common_name1910 ///
		num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 ///
		uncommon_surn1900 uncommon_surn1910 common_surn1900 common_surn1910 ///
		distance poi_name_freq1900 poi_name_freq1910 poi_surn_freq1900 poi_surn_freq1910 ///
		poi_birthyear
		 

		/* Using a Binary tree, so this line is unneccary
		foreach v of var * { 
			drop if missing(`v') 
		}


		local std_vars = "gname_jaro lname_jaro gname_soundex lname_soundex freq namelength1900 namelength1910 race_dist num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 surn_freq distance"


		local cnt = 1
		mat def Z = J(15, 2, 0)

		foreach v in `std_vars' {
			if "`v'" != "true" {
				sum `v'
				mat Z[`cnt', 1] = `r(mean)'
				mat Z[`cnt', 2] = `r(sd)'
				local cnt = `cnt' + 1
				egen std_`v' = std(`v')
				drop `v'
				rename std_`v' `v' 
			}
		}
		*/

		*Because the classifier can't deal with NaNs we still have to put something in
		foreach v of var * {
			replace `v' = -1 if `v' == .
		}
			
		save `name'_scored_take2, replace

		/*
		clear
		svmat Z
		save vir_SDMN, replace
		*/
	}
}
