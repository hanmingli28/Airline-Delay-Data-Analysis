# ANLY640 mini-project
# Author: Hanming Li

-- 1) Find maximal departure delay in minutes for each airline. Sort results from smallest to largest maximum delay. Output airline names and values of the delay.
select al_ID.Name as airline_name, max(al.DepDelayMinutes) as max_delay_min
from al_perf as al, L_AIRLINE_ID as al_ID
where al.DOT_ID_Reporting_Airline = al_ID.ID
group by al_ID.Name
order by max_delay_min asc;
-- 16 row(s) returned

-- 2) Find maximal early departures in minutes for each airline. Sort results from largest to smallest. Output airline names.
select al_ID.Name as airline_name_by_early_dep_desc#, temp.max_early_dep_min
from al_perf as al, L_AIRLINE_ID as al_ID, (select al_ID.ID as ID, ABS(min(al.DepDelay)) as max_early_dep_min
											from al_perf as al, L_AIRLINE_ID as al_ID
                                            where al.DOT_ID_Reporting_Airline = al_ID.ID
                                            group by al_ID.Name) as temp
where al.DOT_ID_Reporting_Airline = al_ID.ID
and al_ID.ID = temp.ID
group by al_ID.Name
order by temp.max_early_dep_min desc;
-- 16 row(s) returned

-- 3)Rank days of the week by the number of flights performed by all airlines on that day ( 1 is the busiest). Output the day of the week names, number of flights and ranks in the rank increasing order.
select w.Day as Weekday, sum(flights) as num_flights, rank() over (order by (sum(flights)) desc) as num_flights_rank
from al_perf as al, L_WEEKDAYS as w
where al.DayOfWeek = w.Code
group by w.Day #al.DayOfWeek
order by num_flights_rank asc;
-- 7 row(s) returned

-- 4) Find the airport that has the highest average departure delay among all airports. Consider 0 minutes delay for flights that departed early. Output one line of results: the airport name, code, and average delay.
select a.Name as airport_name, al.Origin as airport_code, temp.avg_delay_min
from (select al.Origin, avg(al.DepDelayMinutes) as avg_delay_min
	  from al_perf as al
	  group by al.Origin) as temp, al_perf as al, L_AIRPORT as a
where al.Origin = a.Code
and temp.Origin = al.Origin
order by temp.avg_delay_min desc
limit 1;
-- 1 row(s) returned

-- 5) For each airline find an airport where it has the highest average departure delay. Output an airline name, a name of the airport that has the highest average delay, and the value of that average delay.
select t1.airline_name, a.Name as airport_name, t1.avg_delay_min as max_avg_delay_min
from (select al_ID.Name as airline_name, al.OriginAirportID as ID, avg(al.DepDelayMinutes) as avg_delay_min
	  from al_perf as al, L_AIRLINE_ID as al_ID
	  where al.DOT_ID_Reporting_Airline = al_ID.ID
	  group by al_ID.Name, al.OriginAirportID) as t1, (select t.airline_name, max(t.avg_delay_min) as max_avg_delay_min
													   from (select al_ID.Name as airline_name, al.OriginAirportID as ID, avg(al.DepDelayMinutes) as avg_delay_min
															  from al_perf as al, L_AIRLINE_ID as al_ID
															  where al.DOT_ID_Reporting_Airline = al_ID.ID
															  group by al_ID.Name, al.OriginAirportID) as t, L_AIRPORT_ID as a
													   where t.ID = a.ID
													   group by t.airline_name) as t2, L_AIRPORT_ID as a
where t1.avg_delay_min = t2.max_avg_delay_min
and a.ID = t1.ID
order by t1.avg_delay_min desc;
-- 16 row(s) returned

-- 6) a) Check if your dataset has any canceled flights.
-- b) If it does, what was the most frequent reason for each departure airport? Output airport name, the most frequent reason, and the number of cancelations for that reason.
# a) Find the number of cancelled flights
select sum(al.Cancelled) as num_flights_cancelled
from al_perf as al;
-- 1 row(s) returned
# Yes, there are 6238 cancelled flights in the dataset

# b) 
select t2.airport_name, c.Reason, t2.num_cancel
from (select t.airport_name, max(t.num_cancel) as max_num_cancel
		from (select a.Name as airport_name, CancellationCode, count(sml_al.CancellationCode) as num_cancel
			  from (select *
					from al_perf as al
					where al.Cancelled = 1) as sml_al, L_AIRPORT_ID as a
			  where sml_al.OriginAirportID = a.ID
			  group by a.ID, sml_al.CancellationCode
			  order by airport_name) as t
		group by t.airport_name) as t1, (select a.Name as airport_name, CancellationCode, count(sml_al.CancellationCode) as num_cancel
										  from (select *
												from al_perf as al
												where al.Cancelled = 1) as sml_al, L_AIRPORT_ID as a
										  where sml_al.OriginAirportID = a.ID
										  group by a.ID, sml_al.CancellationCode
										  order by airport_name) as t2, L_CANCELATION as c
where t1.airport_name = t2.airport_name
and t1.max_num_cancel = t2.num_cancel
and c.Code = t2.CancellationCode
order by t2.num_cancel desc;
-- 290 row(s) returned

-- 7) Build a report that for each day output average number of flights over the preceding 3 days.
-- drop view v;
create view v as 
	select DayofMonth, sum(Flights) as num_flights
    from al_perf
    group by DayofMonth
    order by DayofMonth asc;
-- 0 row(s) affected
    
select DayofMonth, avg(num_flights)                         
over (order by DayofMonth rows 3 preceding) as avg_num_flights_over_preceding_3D
from v
-- 32 row(s) returned

        
