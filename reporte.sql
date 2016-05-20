use ahana;
drop temporary table if exists marketing_date;
create temporary table marketing_date
as select distinct dt as date from marketing.calendar
where dt between '2015-04-01' and '2015-04-10';
drop temporary table if exists categories;
create temporary table categories(KEY(CatBP))
select distinct CatBP from development_ec.A_Master;

delete from ahana.pruebas;
alter  table marketing_date 
add index date_idx(date);


insert into pruebas
select 
'ARG' as country ,
date ,
date_format(date,'%Y%m') as monthnum ,
affiliate_id,
'' as affiliate_name,
CatBP,
   0 gross_revenue,
   0 net_revenue,
   0 new_gross_revenue,
   0 new_net_revenue,
   0 gross_commission,
   0 net_commission,
   0 gross_new_commission,
   0 net_new_commission,
   0 gross_orders,
   0 net_orders,
   0 new_orders,
   0 returning_orders,
   0 invalid_orders,
   0 returned_orders,
   0 fraud_cancelled_orders,
   0 manual_cancelled_orders,
   0 impressions,
   0 clicks,
   0 sessions ,
   0 bounces,
   1 appear
from 
marketing_date 
join
affiliate_partners
join categories;

drop table if exists affiliates_revenue;
create table affiliates_revenue(Key(country,date,affiliate_id,CatBP))
select distinct a.country, date, monthnum ,
CAST(substring_index(campaign,'-',1) as UNSIGNED INTEGER) as affiliate_id ,
CatBP,
sum(NMV*orderbeforecan)/xr as gross_revenue,
sum(NMV*orderaftercan)/xr as net_revenue,
sum(Case when newreturning = 'new' then ((NMV*orderbeforecan)/xr) END) as new_gross_revenue,
sum(Case when newreturning = 'new' then ((NMV*orderaftercan)/xr) END) as new_net_revenue,
COUNT(Distinct(CASE when orderbeforecan = 1 then ordernum END)) as gross_orders,
COUNT(Distinct(CASE when orderaftercan = 1 then ordernum END)) as net_orders , 
COUNT(Distinct(CASE when orderaftercan = 1 and newreturning = 'new' then ordernum END)) as new_orders,
COUNT(Distinct(CASE when orderaftercan = 1 and newreturning = 'returning' then ordernum END)) as returning_orders,
COUNT(Distinct(CASE when orderbeforecan = 0 then ordernum END)) as invalid_orders,
COUNT(Distinct(CASE when returns = 1 then ordernum END)) as returned_orders,
0 as appear
from development_ar.A_Master  a
join A_E_BI_ExchangeRate_EUR_EXTERNAL_Marketing b 
on a.country = b.country 
and monthnum = month_num
where (campaign like '____-%' or campaign like '_____-%') and channel like '%Ingenious%'
and channelgroup = 'Affiliates' and date between '2015-04-01' and '2015-04-10'
 group by affiliate_id , date, monthnum, CatBP

union 

select distinct a.country, date, monthnum ,  0 as affiliate_id ,
CatBP,
sum(NMV*orderbeforecan)/xr as gross_revenue,
sum(NMV*orderaftercan)/xr as net_revenue, 
sum(Case when newreturning = 'new' then ((NMV*orderbeforecan)/xr) END) as new_gross_revenue,
sum(Case when newreturning = 'new' then ((NMV*orderaftercan)/xr) END) as new_net_revenue,
COUNT(Distinct(CASE when orderbeforecan = 1 then ordernum END)) as gross_orders,
COUNT(Distinct(CASE when orderaftercan = 1 then ordernum END)) as net_orders , 
COUNT(Distinct(CASE when orderaftercan = 1 and newreturning = 'new' then ordernum END)) as new_orders,
COUNT(Distinct(CASE when orderaftercan = 1 and newreturning = 'returning' then ordernum END)) as returning_orders,
COUNT(Distinct(CASE when orderbeforecan = 0 then ordernum END)) as invalid_orders,
COUNT(Distinct(CASE when returns = 1 then ordernum END)) as returned_orders,
0 as appear
from development_ar.A_Master  a
join A_E_BI_ExchangeRate_EUR_EXTERNAL_Marketing b 
on a.country = b.country 
and monthnum = month_num
where (campaign not like '____-%' and campaign not like '_____-%') and channel  like '%Ingenious%'
and channelgroup = 'Affiliates' and date between '2015-04-01' and '2015-04-10'
group by affiliate_id , date , monthnum, CatBP;
drop table if exists appear_temp;
create temporary table appear_temp(Key(date,affiliate_id))
select  date, affiliate_id,
count(*) as appear
from affiliates_revenue 
group by date, affiliate_id;

update affiliates_revenue a
join  appear_temp b
on  a.date = b.date
and a.affiliate_id = b.affiliate_id
set a.appear = b.appear;
 

drop table if exists affiliates_clicks;
create table affiliates_clicks(Key(country,date,affiliate_id))
select country,affiliate_id , date,  date_format(date,'%Y%m') as monthnum , sum(impressions) as impressions , 
sum(clicks) as clicks 
from marketing.affiliates_export 
where country = 'ARG' and date between '2015-04-01' and '2015-04-10'
group by affiliate_id , date , monthnum;

drop table if exists affiliates_visits;
create table affiliates_visits(Key(country , date , affiliate_id))
select distinct country, date, yrmonth, CAST(substring_index(campaign,'-',1) as UNSIGNED INTEGER) as affiliate_id ,
sum(visits) as visits , sum(bounces) as bounces
from marketing_ar.ga_performance
join marketing.channel_group 
on fk_channel_group = id_channel_group
join marketing.channel 
on id_channel = fk_channel 
where (campaign like '____-%' or campaign like '_____-%') and channel like '%ingenious%'
and channel_group = 'Affiliates'  and date between '2015-04-01' and '2015-04-10'
group by affiliate_id , date, yrmonth

union 

select distinct country, date, yrmonth, 0 as affiliate_id ,
sum(visits) as visits , sum(bounces) as bounces
from marketing_ar.ga_performance
join marketing.channel_group 
on fk_channel_group = id_channel_group
join marketing.channel 
on id_channel = fk_channel 
where (campaign not like '____-%' and campaign not like '_____-%') and channel like '%ingenious%'
and channel_group = 'Affiliates'  and date between '2015-04-01' and '2015-04-10'
group by affiliate_id , date, yrmonth;


update pruebas a 
join affiliates_revenue b 
on a.date = b.date 
and a.country = b.country 
and a.affiliate_id = b.affiliate_id
and a.CatBP = b.CatBP
set a.net_revenue = b.net_revenue,
a.gross_revenue = b.gross_revenue, 
a.gross_orders = b.gross_orders,
a.net_orders = b.net_orders, 
a.invalid_orders = b.invalid_orders,
a.returned_orders = b.returned_orders,
a.new_orders = b.new_orders,
a.returning_orders = b.returning_orders,
a.appear = b.appear;

update pruebas a 
join affiliates_clicks b
on a.country = b.country 
and a.date = b.date 
and a.affiliate_id = b.affiliate_id
set a.clicks = b.clicks, 
a.impressions = b.impressions;

update pruebas a 
join affiliates_visits b 
on a.country = b.country 
and a.affiliate_id = b.affiliate_id 
and a.date = b.date 
set a.sessions = b.visits, 
a.bounces = b.bounces;

update pruebas a 
join affiliate_partners b 
on a.affiliate_id = b.affiliate_id 
set a.affiliate_name = b.affiliate_name;

delete from pruebas where gross_revenue = 0 and
net_revenue = 0 and gross_orders = 0 
and net_orders = 0 and new_orders = 0;
select * from affiliates_revenue