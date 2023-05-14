SELECT (first_name || ' '|| last_name) as name, club_id as party,screen_name,color, starting_num, ending_num from
(SELECT * FROM (SELECT ACCOUNT_ID, number_of_followers as starting_num from ( 
  SELECT ACCOUNT_ID, number_of_followers, "date", 
    RANK() OVER (PARTITION BY ACCOUNT_ID ORDER BY "date" DESC) dest_rank
    FROM FOLLOWERS_NUMBER
    WHERE "date" < TO_DATE(STARTING_DATE,'dd-MM-yyyy') 
  ) where dest_rank = 1) 
INNER JOIN
(
  SELECT ACCOUNT_ID, number_of_followers as ending_num from ( 
  SELECT ACCOUNT_ID, number_of_followers, "date", 
    RANK() OVER (PARTITION BY ACCOUNT_ID ORDER BY "date" DESC) dest_rank
    FROM FOLLOWERS_NUMBER
    WHERE "date" < TO_DATE(ENDING_DATE,'dd-MM-yyyy') 
  ) where dest_rank = 1) 
USING(ACCOUNT_ID)
)
 INNER JOIN TWITTER_ACCOUNTS
ON ACCOUNT_ID = TWITTER_ACCOUNTS.ID
INNER JOIN POLITICIANS
ON POLITICIANS.id = TWITTER_ACCOUNTS.politician_id 
INNER JOIN MEMBERS
ON POLITICIANS.id = MEMBERS.politician_id 
INNER JOIN CLUBS
ON MEMBERS.club_id = CLUBS.id
WHERE MEMBERS.is_active=1 
  ORDER BY ACCOUNT_ID