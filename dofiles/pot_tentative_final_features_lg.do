cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg

local files : dir "R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg" files "*.dta"

foreach file in `files' {
	if regexm("`file'", "pot_") & "`file'" != "pot_mat1020.dta" {
	append using `file'
	}
}

		
*this command should do nothing, but I'm keeping it just in case ;)
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


	
foreach v of var * { 
	drop if missing(`v') 
}	

foreach v of var *{
	if "`v'" != "true" {
		egen std_`v' = std(`v')
		drop `v'
	}
	
}
	
save lgpilot_machine, replace

use lgpilot_machine, clear
gen split = runiform()

preserve
keep if split >= 0.2
*drop if split >= 0.6 & true == 0 //This line is unfortunately necessary to balance the dataset
drop split
save lgmachine_training, replace
restore

keep if split < 0.2
drop split
save lgmachine_test, replace

use lgmachine_test, clear
preserve
keep if true == 1
save lgtest_true, replace
restore
keep if true == 0
save lgtest_false, replace


/*
use pilot_smallv8, clear

reg true name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
	gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
	midinit_match freq sex_same namelength1900 namelength1910 same_state same_county ///
	same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
	uncommon_name1900 uncommon_name1910 common_name1900 common_name1910 ///
	num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2

probit true name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
	gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
	midinit_match freq sex_same namelength1900 namelength1910 same_state same_county ///
	same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
	uncommon_name1900 uncommon_name1910 common_name1900 common_name1910 ///
	num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2

logit true name_same gname_jaro lname_jaro birthyr_same birthyr_abs1 birthyr_abs2 birthyr_abs3 ///
	gname_soundex lname_soundex gname_firstl lname_firstl gname_lastl lname_lastl ///
	midinit_match freq sex_same namelength1900 namelength1910 same_state same_county ///
	same_township same_race race_dist same_bpl same_fbpl same_mbpl same_imm_yr ///
	uncommon_name1900 uncommon_name1910 common_name1900 common_name1910 ///
	num_names1900 num_names1910 max_jw_gn max_jw_surn avg_jw_dim1 avg_jw_dim2
*/


