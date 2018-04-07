cd R:\JoePriceResearch\record_linking\projects\deep_learning\census\lg

use pred_pred_ready_virginia, clear

keep if prediction == 1

keep ark1900 ark1910
duplicates drop ark1900 ark1910, force
*Oh good, none are duplicates

replace ark1900 = "https://familysearch.org/ark:/61903/1:1:" + ark1900
replace ark1910 = "https://familysearch.org/ark:/61903/1:1:" + ark1910

save distance_predictions_good


