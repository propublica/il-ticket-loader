create table if not exists wardstotals as
  with
    num_bins as (
      select 15 as num_bins
    ),

    year_bounds as (
      select
        1995 as min_year,
        2019 as max_year
    ),
    wards_toplevel as (
      select
        ward,
        sum(ticket_count) as ticket_count,
        sum(total_payments) as total_payments,
        sum(current_amount_due) as current_amount_due,
        sum(fine_level1_amount) as fine_level1_amount
      from wardsyearly, year_bounds
      where
        (year > min_year and year < max_year)
      group by ward
    ),
    wards_policetickets as (
      select
        ward,
        sum(ticket_count) as police_ticket_count
        from wardsyearly, year_bounds
        where
          (year > min_year and year < max_year)
          and
          (unit_description = 'CPD' or
          unit_description = 'CPD-Other' or
          unit_description = 'CPD-Airport')
        group by ward
    ),
    wards_contestedtickets as (
      select
        ward,
        sum(ticket_count) as contested_ticket_count
        from wardsyearly, year_bounds
        where
          (year > min_year and year < max_year)
          and
          (hearing_disposition = 'Liable' or
          hearing_disposition = 'Not Liable')
        group by ward
    ),
    wards_notliabletickets as (
      select
        ward,
        sum(ticket_count) as notliable_ticket_count
        from wardsyearly, year_bounds
        where
          (year > min_year and year < max_year)
          and
          hearing_disposition = 'Not Liable'
        group by ward
    ),
    wards_bankruptcytickets as (
      select
        ward,
        sum(ticket_count) as bankruptcy_ticket_count
      from wardsyearly, year_bounds
      where
        (year > min_year and year < max_year)
        and
        ticket_queue = 'Bankruptcy'
      group by ward
    ),
    wards_paidtickets as (
      select
      ward,
      sum(ticket_count) as paid_ticket_count
      from wardsyearly, year_bounds
      where
        (year > min_year and year < max_year)
        and
        ticket_queue = 'Paid'
      group by ward
    ),
    wards_dismissedtickets as (
      select
      ward,
      sum(ticket_count) as dismissed_ticket_count
      from wardsyearly, year_bounds
      where
        (year > min_year and year < max_year)
        and
        ticket_queue = 'Dismissed'
      group by ward
    ),
    wards_seizedorsuspendedtickets as (
      select
      ward,
      sum(ticket_count) as seized_or_suspended_ticket_count
      from wardsyearly, year_bounds
      where
        (year > min_year and year < max_year)
        and
        (notice_level = 'SEIZ' or notice_level = 'DLS')
      group by ward
    ),
    wards_summary as (
      select
        t.ward,
        t.ticket_count,
        t.total_payments,
        t.current_amount_due,
        t.fine_level1_amount,
        t.total_payments / (t.current_amount_due + t.total_payments) as paid_pct,
        t.current_amount_due / t.total_payments as debt_to_payment_ratio,
        t.fine_level1_amount / t.ticket_count as avg_per_ticket,
        p.police_ticket_count,
        p.police_ticket_count / t.ticket_count as police_ticket_count_pct,
        c.contested_ticket_count,
        c.contested_ticket_count / t.ticket_count as contested_ticket_count_pct,
        n.notliable_ticket_count / c.contested_ticket_count as contested_and_notliable_pct,
        pd.paid_ticket_count,
        pd.paid_ticket_count/t.ticket_count as paid_ticket_count_pct,
        d.dismissed_ticket_count,
        d.dismissed_ticket_count/t.ticket_count as dismissed_ticket_count_pct,
        s.seized_or_suspended_ticket_count,
        s.seized_or_suspended_ticket_count/t.ticket_count as seized_or_suspended_ticket_count_pct,
        b.bankruptcy_ticket_count,
        b.bankruptcy_ticket_count/t.ticket_count as bankruptcy_ticket_count_pct

      from wards_toplevel t
      join wards_policetickets p on
        t.ward = p.ward
      join wards_contestedtickets c on
        t.ward = c.ward
      join wards_notliabletickets n on
        t.ward = n.ward
      join wards_bankruptcytickets b on
        t.ward = b.ward
      join wards_paidtickets pd on
        t.ward = pd.ward
      join wards_dismissedtickets d on
        t.ward = d.ward
      join wards_seizedorsuspendedtickets s on
        t.ward = s.ward
    ),
    wards_stats as (
      select
        min(ticket_count) as min_ticket_count,
        max(ticket_count) + 1 as max_ticket_count,

        min(current_amount_due) as min_current_amount_due,
        max(current_amount_due) + 1 as max_current_amount_due,

        min(total_payments) as min_total_payments,
        max(total_payments) + 1 as max_total_payments,

        min(fine_level1_amount) as min_fine_level1_amount,
        max(fine_level1_amount) + 1 as max_fine_level1_amount,

        min(avg_per_ticket) as min_avg_per_ticket,
        max(avg_per_ticket) as max_avg_per_ticket,

        min(debt_to_payment_ratio) as min_debt_to_payment_ratio,
        max(debt_to_payment_ratio) as max_debt_to_payment_ratio,

        min(paid_pct) as min_paid_pct,
        max(paid_pct) as max_paid_pct,

        min(police_ticket_count) as min_police_ticket_count,
        max(police_ticket_count) as max_police_ticket_count,

        min(police_ticket_count_pct) as min_police_ticket_count_pct,
        max(police_ticket_count_pct) as max_police_ticket_count_pct,

        min(contested_ticket_count) as min_contested_ticket_count,
        max(contested_ticket_count) as max_contested_ticket_count,

        min(contested_ticket_count_pct) as min_contested_ticket_count_pct,
        max(contested_ticket_count_pct) as max_contested_ticket_count_pct,

        min(contested_and_notliable_pct) as min_contested_and_notliable_pct,
        max(contested_and_notliable_pct) as max_contested_and_notliable_pct,

        min(paid_ticket_count) as min_paid_ticket_count,
        max(paid_ticket_count) as max_paid_ticket_count,

        min(paid_ticket_count_pct) as min_paid_ticket_count_pct,
        max(paid_ticket_count_pct) as max_paid_ticket_count_pct,

        min(dismissed_ticket_count) as min_dismissed_ticket_count,
        max(dismissed_ticket_count) as max_dismissed_ticket_count,

        min(dismissed_ticket_count_pct) as min_dismissed_ticket_count_pct,
        max(dismissed_ticket_count_pct) as max_dismissed_ticket_count_pct,

        min(seized_or_suspended_ticket_count) as min_seized_or_suspended_ticket_count,
        max(seized_or_suspended_ticket_count) as max_seized_or_suspended_ticket_count,

        min(seized_or_suspended_ticket_count_pct) as min_seized_or_suspended_ticket_count_pct,
        max(seized_or_suspended_ticket_count_pct) as max_seized_or_suspended_ticket_count_pct,

        min(bankruptcy_ticket_count) as min_bankruptcy_ticket_count,
        max(bankruptcy_ticket_count) as max_bankruptcy_ticket_count,

        min(bankruptcy_ticket_count_pct) as min_bankruptcy_ticket_count_pct,
        max(bankruptcy_ticket_count_pct) as max_bankruptcy_ticket_count_pct
      from wards_summary
    ),
    wardsranked as (
      select
        ward,

        ticket_count,
        dense_rank() over (order by ticket_count desc) as ticket_count_rank,

        width_bucket(ticket_count, min_ticket_count, max_ticket_count, num_bins) as ticket_count_bucket,
        min_ticket_count + ((max_ticket_count - min_ticket_count) / num_bins) * (width_bucket(ticket_count, min_ticket_count, max_ticket_count, num_bins) - 1) as ticket_count_bucket_min,
        min_ticket_count + ((max_ticket_count - min_ticket_count) / num_bins) * (width_bucket(ticket_count, min_ticket_count, max_ticket_count, num_bins)) as ticket_count_bucket_max,

        current_amount_due,
        dense_rank() over (order by current_amount_due desc) as current_amount_due_rank,

        width_bucket(current_amount_due, min_current_amount_due, max_current_amount_due, num_bins) as current_amount_due_bucket,
        min_current_amount_due + ((max_current_amount_due - min_current_amount_due) / num_bins) * (width_bucket(current_amount_due, min_current_amount_due, max_current_amount_due, num_bins) - 1) as current_amount_due_bucket_min,
        min_current_amount_due + ((max_current_amount_due - min_current_amount_due) / num_bins) * (width_bucket(current_amount_due, min_current_amount_due, max_current_amount_due, num_bins)) as current_amount_due_bucket_max,

        total_payments,
        dense_rank() over (order by total_payments desc) as total_payments_rank,

        width_bucket(total_payments, min_total_payments, max_total_payments, num_bins) as total_payments_bucket,
        min_total_payments + ((max_total_payments - min_total_payments) / num_bins) * (width_bucket(total_payments, min_total_payments, max_total_payments, num_bins) - 1) as total_payments_bucket_min,
        min_total_payments + ((max_total_payments - min_total_payments) / num_bins) * (width_bucket(total_payments, min_total_payments, max_total_payments, num_bins)) as total_payments_bucket_max,

        fine_level1_amount,
        dense_rank() over (order by fine_level1_amount desc) as fine_level1_amount_rank,

        width_bucket(fine_level1_amount, min_fine_level1_amount, max_fine_level1_amount, num_bins) as fine_level1_amount_bucket,
        min_fine_level1_amount + ((max_fine_level1_amount - min_fine_level1_amount) / num_bins) * (width_bucket(fine_level1_amount, min_fine_level1_amount, max_fine_level1_amount, num_bins) - 1) as fine_level1_amount_bucket_min,
        min_fine_level1_amount + ((max_fine_level1_amount - min_fine_level1_amount) / num_bins) * (width_bucket(fine_level1_amount, min_fine_level1_amount, max_fine_level1_amount, num_bins)) as fine_level1_amount_bucket_max,

        avg_per_ticket,
        dense_rank() over (order by avg_per_ticket desc) as avg_per_ticket_rank,

        width_bucket(avg_per_ticket, min_avg_per_ticket, max_avg_per_ticket, num_bins) as avg_per_ticket_bucket,
        min_avg_per_ticket + ((max_avg_per_ticket - min_avg_per_ticket) / num_bins) * (width_bucket(avg_per_ticket, min_avg_per_ticket, max_avg_per_ticket, num_bins) - 1) as avg_per_ticket_bucket_min,
        min_avg_per_ticket + ((max_avg_per_ticket - min_avg_per_ticket) / num_bins) * (width_bucket(avg_per_ticket, min_avg_per_ticket, max_avg_per_ticket, num_bins)) as avg_per_ticket_bucket_max,

        debt_to_payment_ratio,
        dense_rank() over (order by debt_to_payment_ratio desc) as debt_to_payment_ratio_rank,

        width_bucket(debt_to_payment_ratio, min_debt_to_payment_ratio, max_debt_to_payment_ratio, num_bins) as debt_to_payment_ratio_bucket,
        min_debt_to_payment_ratio + ((max_debt_to_payment_ratio - min_debt_to_payment_ratio) / num_bins) * (width_bucket(debt_to_payment_ratio, min_debt_to_payment_ratio, max_debt_to_payment_ratio, num_bins) - 1) as debt_to_payment_ratio_bucket_min,
        min_debt_to_payment_ratio + ((max_debt_to_payment_ratio - min_debt_to_payment_ratio) / num_bins) * (width_bucket(debt_to_payment_ratio, min_debt_to_payment_ratio, max_debt_to_payment_ratio, num_bins)) as debt_to_payment_ratio_bucket_max,

        paid_pct,
        dense_rank() over (order by paid_pct desc) as paid_pct_rank,

        width_bucket(paid_pct, min_paid_pct, max_paid_pct, num_bins) as paid_pct_bucket,
        min_paid_pct + ((max_paid_pct - min_paid_pct) / num_bins) * (width_bucket(paid_pct, min_paid_pct, max_paid_pct, num_bins) - 1) as paid_pct_bucket_min,
        min_paid_pct + ((max_paid_pct - min_paid_pct) / num_bins) * (width_bucket(paid_pct, min_paid_pct, max_paid_pct, num_bins)) as paid_pct_bucket_max,

        police_ticket_count,
        dense_rank() over (order by police_ticket_count desc) as police_ticket_count_rank,

        width_bucket(police_ticket_count, min_police_ticket_count, max_police_ticket_count, num_bins) as police_ticket_count_bucket,
        min_police_ticket_count + ((max_police_ticket_count - min_police_ticket_count) / num_bins) * (width_bucket(police_ticket_count, min_police_ticket_count, max_police_ticket_count, num_bins) - 1) as police_ticket_count_bucket_min,
        min_police_ticket_count + ((max_police_ticket_count - min_police_ticket_count) / num_bins) * (width_bucket(police_ticket_count, min_police_ticket_count, max_police_ticket_count, num_bins)) as police_ticket_count_bucket_max,

        police_ticket_count_pct,
        dense_rank() over (order by police_ticket_count_pct desc) as police_ticket_count_pct_rank,

        width_bucket(police_ticket_count_pct, min_police_ticket_count_pct, max_police_ticket_count_pct, num_bins) as police_ticket_count_pct_bucket,
        min_police_ticket_count_pct + ((max_police_ticket_count_pct - min_police_ticket_count_pct) / num_bins) * (width_bucket(police_ticket_count_pct, min_police_ticket_count_pct, max_police_ticket_count_pct, num_bins) - 1) as police_ticket_count_pct_bucket_min,
        min_police_ticket_count_pct + ((max_police_ticket_count_pct - min_police_ticket_count_pct) / num_bins) * (width_bucket(police_ticket_count_pct, min_police_ticket_count_pct, max_police_ticket_count_pct, num_bins)) as police_ticket_count_pct_bucket_max,

        contested_ticket_count,
        dense_rank() over (order by contested_ticket_count desc) as contested_ticket_count_rank,

        width_bucket(contested_ticket_count, min_contested_ticket_count, max_contested_ticket_count, num_bins) as contested_ticket_count_bucket,
        min_contested_ticket_count + ((max_contested_ticket_count - min_contested_ticket_count) / num_bins) * (width_bucket(contested_ticket_count, min_contested_ticket_count, max_contested_ticket_count, num_bins) - 1) as contested_ticket_count_bucket_min,
        min_contested_ticket_count + ((max_contested_ticket_count - min_contested_ticket_count) / num_bins) * (width_bucket(contested_ticket_count, min_contested_ticket_count, max_contested_ticket_count, num_bins)) as contested_ticket_count_bucket_max,

        contested_ticket_count_pct,
        dense_rank() over (order by contested_ticket_count_pct desc) as contested_ticket_count_pct_rank,

        width_bucket(contested_ticket_count_pct, min_contested_ticket_count_pct, max_contested_ticket_count_pct, num_bins) as contested_ticket_count_pct_bucket,
        min_contested_ticket_count_pct + ((max_contested_ticket_count_pct - min_contested_ticket_count_pct) / num_bins) * (width_bucket(contested_ticket_count_pct, min_contested_ticket_count_pct, max_contested_ticket_count_pct, num_bins) - 1) as contested_ticket_count_pct_bucket_min,
        min_contested_ticket_count_pct + ((max_contested_ticket_count_pct - min_contested_ticket_count_pct) / num_bins) * (width_bucket(contested_ticket_count_pct, min_contested_ticket_count_pct, max_contested_ticket_count_pct, num_bins)) as contested_ticket_count_pct_bucket_max,

        contested_and_notliable_pct,
        dense_rank() over (order by contested_and_notliable_pct desc) as contested_and_notliable_pct_rank,

        width_bucket(contested_and_notliable_pct, min_contested_and_notliable_pct, max_contested_and_notliable_pct, num_bins) as contested_and_notliable_pct_bucket,
        min_contested_and_notliable_pct + ((max_contested_and_notliable_pct - min_contested_and_notliable_pct) / num_bins) * (width_bucket(contested_and_notliable_pct, min_contested_and_notliable_pct, max_contested_and_notliable_pct, num_bins) - 1) as contested_and_notliable_pct_bucket_min,
        min_contested_and_notliable_pct + ((max_contested_and_notliable_pct - min_contested_and_notliable_pct) / num_bins) * (width_bucket(contested_and_notliable_pct, min_contested_and_notliable_pct, max_contested_and_notliable_pct, num_bins)) as contested_and_notliable_pct_bucket_max,

        paid_ticket_count,
        dense_rank() over (order by paid_ticket_count desc) as paid_ticket_count_rank,

        width_bucket(paid_ticket_count, min_paid_ticket_count, max_paid_ticket_count, num_bins) as paid_ticket_count_bucket,
        min_paid_ticket_count + ((max_paid_ticket_count - min_paid_ticket_count) / num_bins) * (width_bucket(paid_ticket_count, min_paid_ticket_count, max_paid_ticket_count, num_bins) - 1) as paid_ticket_count_bucket_min,
        min_paid_ticket_count + ((max_paid_ticket_count - min_paid_ticket_count) / num_bins) * (width_bucket(paid_ticket_count, min_paid_ticket_count, max_paid_ticket_count, num_bins)) as paid_ticket_count_bucket_max,

        paid_ticket_count_pct,
        dense_rank() over (order by paid_ticket_count_pct desc) as paid_ticket_count_pct_rank,

        width_bucket(paid_ticket_count_pct, min_paid_ticket_count_pct, max_paid_ticket_count_pct, num_bins) as paid_ticket_count_pct_bucket,
        min_paid_ticket_count_pct + ((max_paid_ticket_count_pct - min_paid_ticket_count_pct) / num_bins) * (width_bucket(paid_ticket_count_pct, min_paid_ticket_count_pct, max_paid_ticket_count_pct, num_bins) - 1) as paid_ticket_count_pct_bucket_min,
        min_paid_ticket_count_pct + ((max_paid_ticket_count_pct - min_paid_ticket_count_pct) / num_bins) * (width_bucket(paid_ticket_count_pct, min_paid_ticket_count_pct, max_paid_ticket_count_pct, num_bins)) as paid_ticket_count_pct_bucket_max,

        dismissed_ticket_count,
        dense_rank() over (order by dismissed_ticket_count desc) as dismissed_ticket_count_rank,

        width_bucket(dismissed_ticket_count, min_dismissed_ticket_count, max_dismissed_ticket_count, num_bins) as dismissed_ticket_count_bucket,
        min_dismissed_ticket_count + ((max_dismissed_ticket_count - min_dismissed_ticket_count) / num_bins) * (width_bucket(dismissed_ticket_count, min_dismissed_ticket_count, max_dismissed_ticket_count, num_bins) - 1) as dismissed_ticket_count_bucket_min,
        min_dismissed_ticket_count + ((max_dismissed_ticket_count - min_dismissed_ticket_count) / num_bins) * (width_bucket(dismissed_ticket_count, min_dismissed_ticket_count, max_dismissed_ticket_count, num_bins)) as dismissed_ticket_count_bucket_max,

        dismissed_ticket_count_pct,
        dense_rank() over (order by dismissed_ticket_count_pct desc) as dismissed_ticket_count_pct_rank,

        width_bucket(dismissed_ticket_count_pct, min_dismissed_ticket_count_pct, max_dismissed_ticket_count_pct, num_bins) as dismissed_ticket_count_pct_bucket,
        min_dismissed_ticket_count_pct + ((max_dismissed_ticket_count_pct - min_dismissed_ticket_count_pct) / num_bins) * (width_bucket(dismissed_ticket_count_pct, min_dismissed_ticket_count_pct, max_dismissed_ticket_count_pct, num_bins) - 1) as dismissed_ticket_count_pct_bucket_min,
        min_dismissed_ticket_count_pct + ((max_dismissed_ticket_count_pct - min_dismissed_ticket_count_pct) / num_bins) * (width_bucket(dismissed_ticket_count_pct, min_dismissed_ticket_count_pct, max_dismissed_ticket_count_pct, num_bins)) as dismissed_ticket_count_pct_bucket_max,

        seized_or_suspended_ticket_count,
        dense_rank() over (order by seized_or_suspended_ticket_count desc) as seized_or_suspended_ticket_count_rank,

        width_bucket(seized_or_suspended_ticket_count, min_seized_or_suspended_ticket_count, max_seized_or_suspended_ticket_count, num_bins) as seized_or_suspended_ticket_count_bucket,
        min_seized_or_suspended_ticket_count + ((max_seized_or_suspended_ticket_count - min_seized_or_suspended_ticket_count) / num_bins) * (width_bucket(seized_or_suspended_ticket_count, min_seized_or_suspended_ticket_count, max_seized_or_suspended_ticket_count, num_bins) - 1) as seized_or_suspended_ticket_count_bucket_min,
        min_seized_or_suspended_ticket_count + ((max_seized_or_suspended_ticket_count - min_seized_or_suspended_ticket_count) / num_bins) * (width_bucket(seized_or_suspended_ticket_count, min_seized_or_suspended_ticket_count, max_seized_or_suspended_ticket_count, num_bins)) as seized_or_suspended_ticket_count_bucket_max,

        seized_or_suspended_ticket_count_pct,
        dense_rank() over (order by seized_or_suspended_ticket_count_pct desc) as seized_or_suspended_ticket_count_pct_rank,

        width_bucket(seized_or_suspended_ticket_count_pct, min_seized_or_suspended_ticket_count_pct, max_seized_or_suspended_ticket_count_pct, num_bins) as seized_or_suspended_ticket_count_pct_bucket,
        min_seized_or_suspended_ticket_count_pct + ((max_seized_or_suspended_ticket_count_pct - min_seized_or_suspended_ticket_count_pct) / num_bins) * (width_bucket(seized_or_suspended_ticket_count_pct, min_seized_or_suspended_ticket_count_pct, max_seized_or_suspended_ticket_count_pct, num_bins) - 1) as seized_or_suspended_ticket_count_pct_bucket_min,
        min_seized_or_suspended_ticket_count_pct + ((max_seized_or_suspended_ticket_count_pct - min_seized_or_suspended_ticket_count_pct) / num_bins) * (width_bucket(seized_or_suspended_ticket_count_pct, min_seized_or_suspended_ticket_count_pct, max_seized_or_suspended_ticket_count_pct, num_bins)) as seized_or_suspended_ticket_count_pct_bucket_max,

        bankruptcy_ticket_count,
        dense_rank() over (order by bankruptcy_ticket_count desc) as bankruptcy_ticket_count_rank,

        width_bucket(bankruptcy_ticket_count, min_bankruptcy_ticket_count, max_bankruptcy_ticket_count, num_bins) as bankruptcy_ticket_count_bucket,
        min_bankruptcy_ticket_count + ((max_bankruptcy_ticket_count - min_bankruptcy_ticket_count) / num_bins) * (width_bucket(bankruptcy_ticket_count, min_bankruptcy_ticket_count, max_bankruptcy_ticket_count, num_bins) - 1) as bankruptcy_ticket_count_bucket_min,
        min_bankruptcy_ticket_count + ((max_bankruptcy_ticket_count - min_bankruptcy_ticket_count) / num_bins) * (width_bucket(bankruptcy_ticket_count, min_bankruptcy_ticket_count, max_bankruptcy_ticket_count, num_bins)) as bankruptcy_ticket_count_bucket_max,

        bankruptcy_ticket_count_pct,
        dense_rank() over (order by bankruptcy_ticket_count_pct desc) as bankruptcy_ticket_count_pct_rank,

        width_bucket(bankruptcy_ticket_count_pct, min_bankruptcy_ticket_count_pct, max_bankruptcy_ticket_count_pct, num_bins) as bankruptcy_ticket_count_pct_bucket,
        min_bankruptcy_ticket_count_pct + ((max_bankruptcy_ticket_count_pct - min_bankruptcy_ticket_count_pct) / num_bins) * (width_bucket(bankruptcy_ticket_count_pct, min_bankruptcy_ticket_count_pct, max_bankruptcy_ticket_count_pct, num_bins) - 1) as bankruptcy_ticket_count_pct_bucket_min,
        min_bankruptcy_ticket_count_pct + ((max_bankruptcy_ticket_count_pct - min_bankruptcy_ticket_count_pct) / num_bins) * (width_bucket(bankruptcy_ticket_count_pct, min_bankruptcy_ticket_count_pct, max_bankruptcy_ticket_count_pct, num_bins)) as bankruptcy_ticket_count_pct_bucket_max

      from wards_summary, wards_stats, num_bins
  )

  select
    ward,
    ticket_count,
    ticket_count_rank,
    case
      when (ticket_count_rank <= 10) then 'top10'
      when (ticket_count_rank >= 11
            and ticket_count_rank <= 40) then 'middle30'
      when (ticket_count_rank >= 40) then 'bottom10'
    end as ticket_count_rank_type,
    ticket_count_bucket,
    current_amount_due,
    current_amount_due_rank,
    case
      when (current_amount_due_rank <= 10) then 'top10'
      when (current_amount_due_rank >= 11
            and current_amount_due_rank <= 40) then 'middle30'
      when (current_amount_due_rank >= 40) then 'bottom10'
    end as current_amount_due_rank_type,
    current_amount_due_bucket,
    fine_level1_amount,
    fine_level1_amount_rank,
    case
      when (fine_level1_amount_rank <= 10) then 'top10'
      when (fine_level1_amount_rank >= 11
            and fine_level1_amount_rank <= 40) then 'middle30'
      when (fine_level1_amount_rank >= 40) then 'bottom10'
    end as fine_level1_amount_rank_type,
    fine_level1_amount_bucket,
    total_payments,
    total_payments_rank,
    case
      when (total_payments_rank <= 10) then 'top10'
      when (total_payments_rank >= 11
            and total_payments_rank <= 40) then 'middle30'
      when (total_payments_rank >= 40) then 'bottom10'
    end as total_payments_rank_type,
    total_payments_bucket,
    avg_per_ticket,
    avg_per_ticket_rank,
    case
      when (avg_per_ticket_rank <= 10) then 'top10'
      when (avg_per_ticket_rank >= 11
            and avg_per_ticket_rank <= 40) then 'middle30'
      when (avg_per_ticket_rank >= 40) then 'bottom10'
    end as avg_per_ticket_rank_type,
    avg_per_ticket_bucket,
    debt_to_payment_ratio,
    debt_to_payment_ratio_rank,
    case
      when (debt_to_payment_ratio_rank <= 10) then 'top10'
      when (debt_to_payment_ratio_rank >= 11
            and debt_to_payment_ratio_rank <= 40) then 'middle30'
      when (debt_to_payment_ratio_rank >= 40) then 'bottom10'
    end as debt_to_payment_ratio_rank_type,
    debt_to_payment_ratio_bucket,
    paid_pct,
    paid_pct_rank,
    case
      when (paid_pct_rank <= 10) then 'top10'
      when (paid_pct_rank >= 11
            and paid_pct_rank <= 40) then 'middle30'
      when (paid_pct_rank >= 40) then 'bottom10'
    end as paid_pct_rank_type,
    paid_pct_bucket,
    police_ticket_count,
    police_ticket_count_rank,
    case
      when (police_ticket_count_rank <= 10) then 'top10'
      when (police_ticket_count_rank >= 11
            and police_ticket_count_rank <= 40) then 'middle30'
      when (police_ticket_count_rank >= 40) then 'bottom10'
    end as police_ticket_count_rank_type,
    police_ticket_count_pct,
    police_ticket_count_pct_rank,
    case
      when (police_ticket_count_pct_rank <= 10) then 'top10'
      when (police_ticket_count_pct_rank >= 11
            and police_ticket_count_pct_rank <= 40) then 'middle30'
      when (police_ticket_count_pct_rank >= 40) then 'bottom10'
    end as police_ticket_count_pct_rank_type,
    contested_and_notliable_pct,
    contested_and_notliable_pct_rank,
    case
      when (contested_and_notliable_pct_rank <= 10) then 'top10'
      when (contested_and_notliable_pct_rank >= 11
            and contested_and_notliable_pct_rank <= 40) then 'middle30'
      when (contested_and_notliable_pct_rank >= 40) then 'bottom10'
    end as contested_and_notliable_pct_rank_type,
    contested_ticket_count,
    contested_ticket_count_rank,
    case
      when (contested_ticket_count_rank <= 10) then 'top10'
      when (contested_ticket_count_rank >= 11
            and contested_ticket_count_rank <= 40) then 'middle30'
      when (contested_ticket_count_rank >= 40) then 'bottom10'
    end as contested_ticket_count_rank_type,
    contested_ticket_count_pct,
    contested_ticket_count_pct_rank,
    case
      when (contested_ticket_count_pct_rank <= 10) then 'top10'
      when (contested_ticket_count_pct_rank >= 11
            and contested_ticket_count_pct_rank <= 40) then 'middle30'
      when (contested_ticket_count_pct_rank >= 40) then 'bottom10'
    end as contested_ticket_count_pct_rank_type,
    paid_ticket_count,
    paid_ticket_count_rank,
    case
      when (paid_ticket_count_rank <= 10) then 'top10'
      when (paid_ticket_count_rank >= 11
            and paid_ticket_count_rank <= 40) then 'middle30'
      when (paid_ticket_count_rank >= 40) then 'bottom10'
    end as paid_ticket_count_rank_type,
    paid_ticket_count_pct,
    paid_ticket_count_pct_rank,
    case
      when (paid_ticket_count_pct_rank <= 10) then 'top10'
      when (paid_ticket_count_pct_rank >= 11
            and paid_ticket_count_pct_rank <= 40) then 'middle30'
      when (paid_ticket_count_pct_rank >= 40) then 'bottom10'
    end as paid_ticket_count_pct_rank_type,
    dismissed_ticket_count,
    dismissed_ticket_count_rank,
    case
      when (dismissed_ticket_count_rank <= 10) then 'top10'
      when (dismissed_ticket_count_rank >= 11
            and dismissed_ticket_count_rank <= 40) then 'middle30'
      when (dismissed_ticket_count_rank >= 40) then 'bottom10'
    end as dismissed_ticket_count_rank_type,
    dismissed_ticket_count_pct,
    dismissed_ticket_count_pct_rank,
    case
      when (dismissed_ticket_count_pct_rank <= 10) then 'top10'
      when (dismissed_ticket_count_pct_rank >= 11
            and dismissed_ticket_count_pct_rank <= 40) then 'middle30'
      when (dismissed_ticket_count_pct_rank >= 40) then 'bottom10'
    end as dismissed_ticket_count_pct_rank_type,
    seized_or_suspended_ticket_count,
    seized_or_suspended_ticket_count_rank,
    case
      when (seized_or_suspended_ticket_count_rank <= 10) then 'top10'
      when (seized_or_suspended_ticket_count_rank >= 11
            and seized_or_suspended_ticket_count_rank <= 40) then 'middle30'
      when (seized_or_suspended_ticket_count_rank >= 40) then 'bottom10'
    end as seized_or_suspended_ticket_count_rank_type,
    seized_or_suspended_ticket_count_pct,
    seized_or_suspended_ticket_count_pct_rank,
    case
      when (seized_or_suspended_ticket_count_pct_rank <= 10) then 'top10'
      when (seized_or_suspended_ticket_count_pct_rank >= 11
            and seized_or_suspended_ticket_count_pct_rank <= 40) then 'middle30'
      when (seized_or_suspended_ticket_count_pct_rank >= 40) then 'bottom10'
    end as seized_or_suspended_ticket_count_pct_rank_type,
    bankruptcy_ticket_count,
    bankruptcy_ticket_count_rank,
    case
      when (bankruptcy_ticket_count_rank <= 10) then 'top10'
      when (bankruptcy_ticket_count_rank >= 11
            and bankruptcy_ticket_count_rank <= 40) then 'middle30'
      when (bankruptcy_ticket_count_rank >= 40) then 'bottom10'
    end as bankruptcy_ticket_count_rank_type,
    bankruptcy_ticket_count_pct,
    bankruptcy_ticket_count_pct_rank,
    case
      when (bankruptcy_ticket_count_pct_rank <= 10) then 'top10'
      when (bankruptcy_ticket_count_pct_rank >= 11
            and bankruptcy_ticket_count_pct_rank <= 40) then 'middle30'
      when (bankruptcy_ticket_count_pct_rank >= 40) then 'bottom10'
    end as bankruptcy_ticket_count_pct_rank_type

  from wardsranked
;

