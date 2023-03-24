import sqlalchemy
import pandas as pd
from sqlalchemy.orm import sessionmaker
import requests
import json
from datetime import datetime, timedelta
import sqlite3

DATABASE_LOCATION = "sqlite://my_played_tracks.sqlite"
USER_ID = "31whz5uj4rp3lv3h4wkginzb6yna"
TOKEN = "BQDomrMn6D59FzHS6exzfRpjs18vGgT1aFJuUAeAOvCAPLcoxC_jZANJoxjolG7bPz7Mt31ebM-krya80d3vsGh-nbAmmpIYS5kd1ZC707f2nrXUoHShBRiStjK2cieKmkv-8TRUQmslzGmeCoM9tFYlnPCxIkl4RhRAMipz3UCsAFlj4du8eKFbsEpGtluEIaO4sjjtWA"

def check_if_valid_data(df: pd.DataFrame):
    #Check if the dataframe is empty
    if df.empty:
        print("No songs downloaded. Finishing execution.")
        return False
    
    #Primary Key Check
    if pd.Series(df['played_at']).is_unique:
        pass
    else:
        raise Exception("Primary Key check is violated")
    
    #Check for nulls
    if df.isnull().values.any():
        raise Exception("Null value found")
     
    #check all timestamps are from last 24 hrs
    yesterday = datetime.now() - datetime.timedelta(days = 1)
    yesterday = yesterday.replace(hour = 0, minute = 0, second = 0, microsecond = 0)

    timestamps = df["timestamp"].tolist()
    for timestamp in timestamps:
        if datetime.strptime(timestamp, "%Y-%m-%d") != yesterday:
            raise Exception("At least one of the songs do not comes from last 24 hrs")
        
    return True

if __name__ == '__main__':
    headers = {
        "Accept": "application/json",
        "content-Type" : "application/json",
        "Authorization" : "Bearer {token}".format(token = TOKEN)
    }

    today = datetime.now()
    yesterday = today - timedelta(days = 1)
    yesterday_unix_timestamp = int(yesterday.timestamp()) * 1000

    r = requests.get("https://api.spotify.com/v1/me/player/recently-played?after={time}".format(time = yesterday_unix_timestamp), headers= headers)

    data = r.json()

    song_names = []
    artist_names = []
    played_at_list = []
    timestamps = []

    for song in data["items"]:
        song_names.append(song["track"]["name"])
        artist_names.append(song["track"]["album"]["artists"][0]["name"])
        played_at_list.append(song["played_at"])
        timestamps.append(song["played_at"][0:10])
    
    song_dict = {
        "song_name" : song_names,
        "artist_name": artist_names,
        "played_at" : played_at_list,
        "timestamp" : timestamps
    }

    song_df = pd.DataFrame(song_dict, columns = ["song_name", "artist_name", "played_at", "timestamp"])
    
    #Validate
    if check_if_valid_data(song_df):
        print("Data valid, move to load stage")

    engine = sqlalchemy.create_engine(DATABASE_LOCATION)
    conn = sqlite3.connect("my_played_tracks.sqlite")
    cursor = conn.cursor()

    sql_query = """"
    CREATE TABLE IF NOT EXISTS my_played_tracks
    song_name VARCHAR(200),
    artist_name VARCHAR(200),
    played_at VARCHAR(200),
    timestamp VARCHAR(200),
    CONSTRAINT primary_key_constraint PRIMARY KEY(played_at)
    """

    cursor.execute(sql_query)
    print("Opened Database successfully")

    try:
        song_df.to_sql("my_played_tracks", engine, index= False, if_exists="append")
    except:
        print("Data already exists in the database")

    conn.close()
    print("close database ran successfully")
