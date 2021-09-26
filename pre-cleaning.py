import pandas as pd


df = pd.read_csv("arabica_data.csv")
cols = df.select_dtypes('object').columns
unwanted = '|'.join(['other', 'Other', 'Nan', 'nan','none', 'None','NONE'])


for col in cols:
    df[col] = df[col].astype(str).replace( '[^a-zA-Z0-9.,()_]', ' ', regex=True)
    df[col] = df[col].str.slice(0, 30)
    df[col]=df[col].str.replace(unwanted, '')




df['Expiration']=df['Expiration'].str.replace('\b(\d+)\s*(st|nd|rd|th)\b', '', regex = True)
df['Grading.Date']=df['Grading.Date'].str.replace( '\b(\d+)\s*(st|nd|rd|th)\b' , '', regex = True)

df['Expiration']= pd.to_datetime(df['Expiration'])
df['Grading.Date']=pd.to_datetime(df['Grading.Date'])

df['Expiration'] = df['Expiration'].dt.strftime('%b %d, %Y')
df['Grading.Date'] = df['Grading.Date'].dt.strftime('%b %d, %Y')

    
df.to_csv('coffee_data.csv')
    

