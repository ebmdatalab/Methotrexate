cd "C:\Users\Alex\Documents\GitHub\Methotrexate"
import delimited "methotrexate_for_analysis.csv",clear

*misstable summ,all
gen num_gps = num_gps_june
replace num_gps = num_gps_sept if num_gps ==.

recode rate 0/0.0999999999999=0 0.1/max=1, gen(rate_bin)

xtile qof = total, nq(5)
xtile imd = value_imd, nq(5)
xtile composite_score = mean_percentile, nq(5)
recode num_gps min/1=1 2/max=0 .=0, gen(single_handed)
recode rural_urban_code 1=6 2=5 3=4 4=3 5=2 6=1,gen(rural_urban)
xtile over_65 = value_over_65,nq(5)
xtile under_18 = value_under_18,nq(5)
xtile long_term_health = value_long_term_health,nq(5)

tabstat value_over_65,by(over_65) s(min max)
tabstat value_under_18,by(under_18) s(min max)
tabstat value_long_term_health,by(long_term_health) s(min max)
tabstat total,by(qof) s(min max)
encode principalsupplier, gen(principalsupplier_e)

foreach indepvar in over_65 under_18 long_term_health single_handed rural_urban imd qof composite_score principalsupplier_e {
	tab `indepvar' rate_bin ,row nofr
	logit rate_bin i.`indepvar' , or
}

melogit rate_bin i.over_65 i.under_18 i.long_term_health i.single_handed i.rural_urban i.imd i.qof i.composite_score i.principalsupplier_e || pct: , or

predict predictions
qui corr rate_bin predictions
di "R-squared - fixed effects (%): " round(r(rho)^2*100,.1)

qui predict predictionsr, reffects
qui corr rate_bin predictionsr
di "R-squared - random effects (%): " round(r(rho)^2*100,.1)
