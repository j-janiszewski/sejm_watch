from config import db_session
import pandas as pd
import subprocess
import sys
import datetime

def get_date_range()-> tuple[str]:
    """Returns beginning (Monday) and end (Sunday) of a week two weeks ago 

    Returns:
        tuple[str]: starting and ending dates 
    """    
    now = datetime.datetime.now() 
    start = now + datetime.timedelta(days=-now.weekday(),weeks=-2)
    end = start + datetime.timedelta(days=6)

    start = start.strftime("%d-%m-%Y")
    end = end.strftime("%d-%m-%Y")

    return start, end



plot_type = sys.argv[1]
# read matching sql query and place date ranges inside 
with open(f"sql_queries/{plot_type}.sql","r") as f:
    query = f.read()
starting_date, ending_date = get_date_range()
query=query.replace("STARTING_DATE",f"'{starting_date}'")
query=query.replace("ENDING_DATE", f"'{ending_date}'")

# getting data from db
engine = db_session()
with engine.connect() as conn:
    df =pd.read_sql(query, con=conn)

# Saving date ranges and db data, both files wil be used by R script
with open("dates.txt","w") as f:
            f.writelines([starting_date, "\n",ending_date, "\n"])
df.to_csv(f"{plot_type}.csv", index=False)


# running R script that will create plot and post status with it
ret = subprocess.call(["Rscript",f"r_ggplot_scripts/{plot_type}.R"])
