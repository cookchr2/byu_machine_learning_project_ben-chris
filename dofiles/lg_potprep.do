cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg
	
use lg_SDMN, clear

mkmat Z1 Z2, mat(Z)

clear

local files : dir "R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg" files "pot_*_*.dta"

foreach file in `files' {

	use `file'

	local std_vars = "gname_jaro lname_jaro gname_soundex lname_soundex freq namelength1900 namelength1910 race_dist num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2 surn_freq"
	local cnt = 1
	foreach v in `std_vars' {
		replace `v' = (`v' - Z[`cnt',1])/Z[`cnt',2]
		local cnt = `cnt' + 1
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
	surn_freq uncommon_surn1900 uncommon_surn1910 common_surn1900 common_surn1910 ///
	ark1900 ark1910

	save rd1_`file', replace

}



