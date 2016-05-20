drop table if exists basket;
create temporary table basket (Key(affiliate_id, date, country, CatBP))
Select date, country, order_id,basket_index,product_number

/*Costo del 2015 a enero 2016
*/
Select g.country, g.MonthNum, g.date,date_format(date,'%Y%m') as MonthNum,
'Affiliates' as channel_group, 
channel, affiliate_id,order_ID as OrderNum,
product_ID as SKUSimple,
sum(commission_paid) as cost,
product_category_label
cost/xr as marketing_cost 
from marketing.Ingenious_BasketExport g
join A_E_BI_ExchangeRate_EUR_EXTERNAL_Marketing m
on g.monthnum = m.monthnum  
and g.country + m.country
where (g.date between '2015-01-01' and '2016-01-31') 
and product_quantity = 1 and country  = 'ARG' 
group by country, date, MonthNum, channel,affiliate_id,product_category_label, order_ID, product_id)  ;

union
/*Costo despues de enero
*/

Select P.country,
P.MonthNum,
P.date,
'Affiliates' channel_group,
channel,
affiliate_id,
OrderNum,
SKUSimple, marketing_cost /xr as marketing_cost from (SELECT 
a.country,
a.MonthNum,
a.date,
'Affiliates' channel_group,
channel,
affiliate_id,
OrderNum,
SKUSimple,
SUM(CASE
WHEN keyword NOT LIKE '%!_COBRAND!_%' ESCAPE '!' THEN commission
END) AS marketing_cost
FROM
(SELECT DISTINCT
a.country,
DATE_FORMAT(a.date, '%Y%m') AS MonthNum,
a.date,
a.channel,
affiliate_id,
a.order_ID AS OrderNum,
b.itemid,
a.product_ID AS SKUSimple,
product_commission_total AS commission,
a.channel_group,
b.ga_keyword AS keyword
FROM
marketing.Ingenious_BasketExport a
JOIN development_:8:.A_Master b ON a.order_ID = b.Ordernum
AND a.product_ID = b.SKUSimple
AND a.country = b.country
WHERE
a.country = ':6:'
AND b.orderaftercan = 1
AND a.date >= '2016-02-01'
AND ventureID = 1
AND ChannelGroup IN ('Affiliates')
GROUP BY country, a.channel , ordernum , b.itemid) a
GROUP BY a.country , date , channel , OrderNum , SKUSimple) P JOIN
regional.M_ExchangeRate m ON P.monthnum = m.monthnum and type = 'EXTERNAL' and currency = 'EUR';"