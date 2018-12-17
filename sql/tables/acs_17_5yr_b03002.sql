create table if not exists public.acs_17_5yr_b03002 (
  id character varying,
  geoid character varying,
  geography character varying,

  total bigint,
  total_moe bigint,

  not_hispanic bigint,
  not_hispanic_moe bigint,

  not_hispanic_white bigint,
  not_hispanic_white_moe bigint,

  not_hispanic_black bigint,
  not_hispanic_black_moe bigint,

  not_hispanic_native bigint,
  not_hispanic_native_moe bigint,

  not_hispanic_asian bigint,
  not_hispanic_asian_moe bigint,

  not_hispanic_pacific_islander bigint,
  not_hispanic_pacific_islander_moe bigint,

  not_hispanic_other bigint,
  not_hispanic_other_moe bigint,

  not_hispanic_two_or_more bigint,
  not_hispanic_two_or_more_moe bigint,

  not_hispanic_two_or_more_including_other bigint,
  not_hispanic_two_or_more_including_other_moe bigint,

  not_hispanic_three_or_more bigint,
  not_hispanic_three_or_more_moe bigint,

  hispanic bigint,
  hispanic_moe bigint,

  hispanic_white bigint,
  hispanic_white_moe bigint,

  hispanic_black bigint,
  hispanic_black_moe bigint,

  hispanic_native bigint,
  hispanic_native_moe bigint,

  hispanic_asian bigint,
  hispanic_asian_moe bigint,

  hispanic_pacific_islander bigint,
  hispanic_pacific_islander_moe bigint,

  hispanic_other bigint,
  hispanic_other_moe bigint,

  hispanic_two_or_more bigint,
  hispanic_two_or_more_moe bigint,

  hispanic_two_or_more_including_other bigint,
  hispanic_two_or_more_including_other_moe bigint,

  hispanic_three_or_more bigint,
  hispanic_three_or_more_moe bigint

)
