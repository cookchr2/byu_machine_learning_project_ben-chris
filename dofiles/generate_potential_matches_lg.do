set more off, perm
cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg

local states1900 = "Alabama Arkansas California Colorado Connecticut Delaware District_of_Columbia Florida Foreign Georgia Hawaii Idaho Illinois Indian_Territory Indiana Iowa Kansas Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada New_Hampshire New_Jersey New_Mexico_Territory New_York_part1 New_York_part2 North_Carolina North_Dakota Ohio Oregon Pennsylvania_part1 Pennsylvania_part2 Rhode_Island South_Carolina South_Dakota Tennessee Texas Utah Vermont Virginia Washington West_Virginia Wisconsin Wyoming"
local states1910 = "Alabama" // Alaska Arizona Arkansas California Colorado Connecticut Delaware District_of_Columbia Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada New_Hampshire New_Jersey New_Mexico New_York_part1 New_York_part2 North_Carolina North_Dakota Ohio Oklahoma Oregon Pennsylvania_part1 Pennsylvania_part2 Rhode_Island South_Carolina South_Dakota Tennessee Texas Utah Vermont Virginia Washington West_Virginia Wisconsin Wyoming"


foreach state in `states1900' {
	foreach state1 in `states1910' { 
		use R:\JoePriceResearch\record_linking\data\census_1910\data\state_files\\`state', clear
		split event_place, p(",")
		replace event_place1 = event_place1 + "," + event_place2 if event_place5 != ""
		replace event_place2 = event_place3 if event_place5 != ""
		replace event_place3 = event_place4 if event_place5 != ""
		replace event_place4 = event_place5 if event_place5 != ""
		drop event_place5

		rename event_place2 event_county
		rename event_place3 event_state
		rename event_place4 event_country
		drop event_place1
		drop event_place
		append using R:\JoePriceResearch\record_linking\data\census_1900\census1900_raw\data\state_files\\`state1'



		rename event_township township
		rename event_county county
		rename event_state state 
		rename pr_name_gn poi_name_gn
		rename pr_name_surn poi_name_surn

		destring pr_age, replace

		gen poi_birthyear = 1900 - pr_age if ark1900 != ""
		replace poi_birthyear = 1910 - pr_age if ark1910 != ""

		gen poi_birthplace = pr_birth_place if ark1900 != ""
		replace poi_birthplace = pr_bir_place if ark1910 != ""
		gen poi_mbpl = pr_mthr_birth_place if ark1900 != ""
		replace poi_mbpl = pr_mthr_bir_place if ark1910 != ""
		gen poi_fbpl = pr_fthr_birth_place if ark1900 != ""
		replace poi_fbpl = pr_fthr_bir_place if ark1910 != ""

		rename pr_sex_code poi_sex
		rename pr_race_or_color poi_race

		gen poi_imm_yr = pr_immigration_year if ark1900 != ""
		replace poi_imm_yr = pr_imm_year if ark1910 != ""

		keep ark1900 ark1910 township county state poi_name_gn ///
		poi_name_surn poi_birthyear poi_birthplace poi_mbpl ///
		poi_fbpl poi_sex poi_race poi_imm_yr 

		*Now I'm going to bin our data

		destring poi_birthyear, replace

		gen birth_bin = round(poi_birthyear, 5)
		gen gn_stub = substr(poi_name_gn, 1, 2)
		egen close_name_gn = group(gn_stub)

		gen surn_stub = substr(poi_name_surn, 1, 2)
		egen close_name_surn = group(surn_stub)

		egen bin = group(birth_bin close_name_gn surn_stub poi_birthplace poi_sex poi_mbpl poi_fbpl)

		/*
		save temp1, replace
		use temp1, clear
		*/

		**For tractibility purposes, we're only matching bins of under 16
		bys bin: gen binsize = _N
		keep if binsize <= 15

		**Next, we're only going to match across DIFFERENT censuses 
		gen bin_copy = bin

		replace bin = . if ark1900 == ""
		replace bin_copy = . if ark1910 == ""

		drop binsize birth_bin-close_name_surn
		compress

		save temp, replace

		foreach v of var * {
			if "`v'" != "ark1900" & "`v'" != "ark1910" {
				rename `v' `v'1910
			}
		}

		drop bin1
		rename bin_copy1 bin
		drop if bin == .
		save temp2, replace

		use temp, clear
		drop if bin == .
		drop ark1910
		foreach v of var * {
			if "`v'" != "ark1900" & "`v'" != "ark1910" {
				rename `v' `v'1900
			}
		}
		rename bin1900 bin
		joinby bin using temp2 //Yeah this line can totally destroy you :)
		drop bin_copy1900 


		********************************************************************************
		********************************************************************************
		********************************************************************************


		
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

		keep name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
		gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
		midinit_match freq sex_same namelength1900 namelength1910 same_state same_county /// 
		same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
		uncommon_name1900 uncommon_name1910 common_name1900 common_name1910 ///
		num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 ///
		surn_freq uncommon_surn1900 uncommon_surn1910 common_surn1900 common_surn1910
		
		
		order freq gname_jaro gname_firstl gname_lastl gname_soundex lname_jaro ///
		lname_firstl lname_lastl lname_soundex name_same birthyr_abs1 birthyr_abs2 ///
		birthyr_abs3 birthyr_same midinit_match sex_same namelength1900 namelength1910 ///
		same_township same_race race_dist uncommon_name1900 uncommon_name1910 ///
		common_name1900 common_name1910 num_names1900 num_names1910 max_jw_gn ///
		max_jw_surn avg_jw_dim1 avg_jw_dim2 same_bpl same_mbpl same_fbpl same_imm_yr ///
		surn_freq uncommon_surn1900 uncommon_surn1910 common_surn1900 common_surn1910

		save pot_`state'_`state1'
			
	}
}


	
