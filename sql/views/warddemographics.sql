create table warddemographics as
  select
		w.ward,
		sum(total) as total,
		sum(race.not_hispanic_white) as white,
		sum(race.not_hispanic_white) / sum(race.total) as white_pct,
		sum(race.not_hispanic_black) as black,
		sum(race.not_hispanic_black) / sum(race.total) as black_pct,
		sum(race.not_hispanic_asian) as asian,
		sum(race.not_hispanic_asian) / sum(race.total) as asian_pct,
		sum(race.hispanic) as latino,
		sum(race.hispanic) / sum(race.total) as latino_pct
	from wards w
	join
		tl_2016_17_bg bg on
			st_within(bg.wkb_geometry, w.wkb_geometry)
	join
		acs_17_5yr_b03002 race on
			bg.geoid = race.geoid
	group by w.ward;
