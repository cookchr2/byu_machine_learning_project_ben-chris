cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg
local files : dir "R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg" files "pot_*_*.dta"

foreach file in `files' {
	use `file', clear
	
	replace gname_firstl = 0.1644128 if gname_firstl == 1
	replace gname_firstl = -6.08225 if gname_firstl == 0
	replace gname_lastl = -.7263882 if gname_lastl == 0
	replace gname_lastl = 1.376674 if gname_lastl == 1
	replace lname_firstl = .1326122 if lname_firstl == 1
	replace lname_firstl = -7.540784 if lname_firstl == 0
	replace lname_lastl = 1.181655 if lname_lastl == 1
	replace lname_lastl = -.8462709 if lname_lastl == 0
	replace name_same = 2.826826 if name_same == 1
	replace name_same = -.3537536 if name_same == 0
	replace birthyr_abs1 = -.7723448 if birthyr_abs1 == 0
	replace birthyr_abs1 = 1.294758 if birthyr_abs1 == 1
	replace birthyr_abs2 = -.4941905 if birthyr_abs2 == 0
	replace birthyr_abs2 = 2.023511 if birthyr_abs2 == 1
	replace birthyr_abs3 = -.3613457 if birthyr_abs3 == 0
	replace birthyr_abs3 = 2.767432 if birthyr_abs3 == 1
	replace birthyr_same = -.5680063 if birthyr_same == 0
	replace birthyr_same = 1.760544 if birthyr_same == 1
	replace midinit_match = -.3213001 if midinit_match == 0
	replace midinit_match = 3.112355 if midinit_match == 1
	replace sex_same = -25.14518 if sex_same == 0
	replace sex_same = .0397691 if sex_same == 1
	replace same_township = -.0735904 if same_township == 0
	replace same_township = 13.58873 if same_township == 1
	replace same_race = -3.41917 if same_race == 0
	replace same_race = .2924686 if same_race == 1
	replace uncommon_name1900 = -.1743849 if uncommon_name1900 == 0
	replace uncommon_name1900 = 5.73444 if uncommon_name1900 == 1
	replace uncommon_name1910 = -.1797168 if uncommon_name1910 == 0
	replace uncommon_name1910 = 5.564309 if uncommon_name1910 == 1
	replace common_name1900 = -.3167692 if common_name1900 == 0
	replace common_name1900 = 3.156873 if common_name1900 == 1
	replace common_name1910 = -.29972 if common_name1910 == 0
	replace common_name1910 = 3.336447 if common_name1910 == 1
	replace same_bpl = -7.67648 if same_bpl == 0
	replace same_bpl = .130268 if same_bpl == 1
	replace same_mbpl = -4.413576 if same_mbpl == 0
	replace same_mbpl = .2265736 if same_mbpl == 1
	replace same_fbpl = -4.340109 if same_fbpl == 0
	replace same_fbpl = .230409 if same_fbpl == 1
	replace same_imm_yr = -.0830964 if same_imm_yr == 0
	replace same_imm_yr = 12.03422 if same_imm_yr == 1
	replace uncommon_surn1900 = -.1896069 if uncommon_surn1900 == 0
	replace uncommon_surn1900 = 5.274068 if uncommon_surn1900 == 1
	replace uncommon_surn1910 = -.2097516 if uncommon_surn1910 == 0
	replace uncommon_surn1910 = 4.767544 if uncommon_surn1910 == 1
	replace common_surn1900 = -.1081244 if common_surn1900 == 0
	replace common_surn1900 = 9.248603 if common_surn1900 == 1
	replace common_surn1910 = -.1082855 if common_surn1910 == 0
	replace common_surn1910 = 9.234845 if common_surn1910 == 1
	replace same_state = -4.172787 if same_state == 0
	replace same_state = .239648 if same_state == 1
	replace same_county = -.5741716 if same_county == 0
	replace same_county = 1.741639 if same_county == 1
	
	local std_vars = "gname_jaro lname_jaro gname_soundex lname_soundex freq namelength1900 namelength1910 race_dist num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 surn_freq"

	foreach v in `std_vars' {
		egen std_`v' = std(`v')
		drop `v'
		rename std_`v' `v'
	}
	
	foreach v of var * { 
	drop if missing(`v') 
		}	


	order freq gname_jaro gname_firstl gname_lastl gname_soundex lname_jaro ///
	lname_firstl lname_lastl lname_soundex name_same birthyr_abs1 birthyr_abs2 ///
	birthyr_abs3 birthyr_same midinit_match sex_same namelength1900 namelength1910 ///
	same_township same_race race_dist uncommon_name1900 uncommon_name1910 ///
	common_name1900 common_name1910 num_names1900 num_names1910 max_jw_gn ///
	max_jw_surn avg_jw_dim1 avg_jw_dim2 same_bpl same_mbpl same_fbpl same_imm_yr ///
	surn_freq uncommon_surn1900 uncommon_surn1910 common_surn1900 common_surn1910
	
	save ready_`file'

	
}



