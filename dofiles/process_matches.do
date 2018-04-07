cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg
	
local files : dir "R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg" files "pred_rd1*.dta"
clear
foreach file in `files' {

	append using `file'
	keep if prediction > 0.5
	keep ark1900 ark1910 prediction
}

replace ark1900 = "https://familysearch.org/ark:/61903/1:1:" + ark1900
replace ark1910 = "https://familysearch.org/ark:/61903/1:1:" + ark1910

set seed 2259
tempvar sortorder
gen `sortorder' = runiform()
sort `sortorder'


save lg_predictions, replace

keep if _n < 10001 


gen type = ""
replace type = "F" if prediction < 0.8
replace type = "E" if prediction < 0.95 & prediction >=0.8
replace type = "D" if prediction >= 0.95
replace type = "C" if prediction >= 0.99
replace type = "B" if prediction >= 0.999
replace type = "A" if prediction >= 0.9999

drop prediction

outsheet using "predicted_matches_lg.csv", non comma replace
