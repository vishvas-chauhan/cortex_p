import argparse
import pandas as pd 

# Define argument parser
parser = argparse.ArgumentParser()
parser.add_argument("--OF", help="operation flag to set", type=str)
args = parser.parse_args()

df = pd.read_parquet(r'adr6.parquet')

def flag_edit(client_):
    if args.OF:
        df.loc[df['client'] == str(client_), 'operation_flag'] = args.OF
        print(f'\n client number {client_} has bee modified 🏠 🛠 ')

flag_edit("050")
df.to_parquet('adr6_test.parquet', index=False)
