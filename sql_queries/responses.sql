SELECT (first_name || ' ' || last_name) as name,
    club_id as party,
    screen_name,
    color,
    COUNT(*) as n
FROM POLITICIANS
    INNER JOIN MEMBERS ON POLITICIANS.id = MEMBERS.politician_id
    INNER JOIN CLUBS ON MEMBERS.club_id = CLUBS.id
    INNER JOIN TWITTER_ACCOUNTS ON POLITICIANS.id = TWITTER_ACCOUNTS.politician_id
    INNER JOIN TWEETS ON TWITTER_ACCOUNTS.id = TWEETS.user_id
WHERE MEMBERS.is_active = 1
    AND TWITTER_ACCOUNTS.is_active = 1
    AND TWEETS.created_at >= TO_DATE(STARTING_DATE, 'dd-MM-yyyy')
    AND TWEETS.created_at <= TO_DATE(ENDING_DATE, 'dd-MM-yyyy')
    AND TWEETS.reply_to_status_id IS NOT NULL
GROUP BY first_name,
    second_name,
    last_name,
    club_id,
    screen_name,
    color
ORDER BY n DESC
FETCH FIRST 7 ROWS ONLY