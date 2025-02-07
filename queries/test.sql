--  check missing matches
select
    s.id,
    s.name,
    s.season,
    s.status_id,
    s.status_name,
    s.verified,
    m.match_id,
    m.datetime
from schedule as s
left join matches as m on s.id = m.match_id
where m.match_id is null
order by s.season, s.id;