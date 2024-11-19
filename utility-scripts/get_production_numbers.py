from metacat.webapi import MetaCatClient
import operator
import subprocess
from argparse import ArgumentParser as ap
import matplotlib.pyplot as plt
import numpy as np
import h5py as h5

def build_reco_query(args, query, good_wfs_list, month, day):
  if args.alt:
    if f'{month}-{day}-2024' not in good_wfs_list.keys(): return ''
    wfs = good_wfs_list[f'{month}-{day}-2024']
    child_query = (
      'files where core.data_tier=full-reconstructed and dune.output_status=confirmed'
      f' and dune.workflow["workflow_id"] in ({",".join(wfs)})')
  else:
    child_query = f'children({query}) where core.data_tier=full-reconstructed and dune.output_status=confirmed'
    if args.workflows is not None:
      child_query += f' and dune.workflow["workflow_id"] in ({good_wfs_list})'

  return child_query
def process(args):
  day_strings = [
    f"0{i}" if i < 10 else str(i) for i in args.days
  ]
  print(day_strings)
  #months = ["06", "07", "08", "09"]
  #if args.test: months = months[1:]

  mc = MetaCatClient()


  base_query = (" and core.run_type=hd-protodune "
                "and core.file_type=detector and core.data_tier=raw and "
                "core.data_stream in (physics, cosmics)")

  if args.workflows is not None and not args.alt:
    with open(args.workflows, 'r') as file_in:
      good_wfs_list = ', '.join([i.strip() for i in file_in.readlines()])
      print(good_wfs_list)
  elif args.workflows is not None and args.alt:
    with open(args.workflows, 'r') as file_in:
      good_wfs_list = {i.strip().split(',')[0]:i.strip().split(',')[1:] for i in file_in.readlines()}
      print(good_wfs_list)

  nfiles = []
  nfiles_reco = []
  nevents_reco = []
  months_out = []
  days_out = []
  nevents = []
  #start = 0 if month != "06" else 18
  #if month in ["06", "09"]: end = 30
  #else: end = 31

  month = args.month 
  month = f'0{month}' if month < 10 else str(month)
  for day, daystr in zip(args.days, day_strings):
    print(month, day)
    query = (f"files where created_timestamp >= 2024{month}{daystr}T0000 and "
             f"created_timestamp < 2024{month}{daystr}T2400 ") + base_query
    files = [i for i in mc.query(query, with_metadata=True)]
    nfiles.append(len(files))
    months_out.append(int(month))
    days_out.append(day)
    total = 0
    for f in files:
      total += f['metadata']['core.event_count']
    nevents.append(total)

    child_query = build_reco_query(args, query, good_wfs_list, month, daystr)
    #print('Checking children')
    #child_query = f'children({query}) where core.data_tier=full-reconstructed and dune.output_status=confirmed'
    #if args.workflows is not None:
    #  child_query += f' and dune.workflow["workflow_id"] in ({good_wfs_list})'

    print(child_query)
    if child_query == '':
      keepup_files = []
    else:
      keepup_files = [i for i in mc.query(child_query, with_metadata=True)]
    print('Got', len(keepup_files))
    nfiles_reco.append(len(keepup_files))

    total = 0
    for f in keepup_files:
      total += f['metadata']['core.event_count']
    nevents_reco.append(total)

  with h5.File(args.o, 'w') as h5f:
    h5f.create_dataset("nfiles", data=nfiles)
    h5f.create_dataset("nevents", data=nevents)
    h5f.create_dataset("months", data=months_out)
    h5f.create_dataset("days", data=days_out)
    h5f.create_dataset("nfiles_reco", data=nfiles_reco)
    h5f.create_dataset("nevents_reco", data=nevents_reco)

def merge(args):
  nfiles = []
  nfiles_reco = []
  nevents = []
  nevents_reco = []
  months_out = []
  days_out = []

  for fn in args.files:
    f = h5.File(fn, 'r')
    with h5.File(fn, 'r') as f:
      nfiles += [i for i in f['nfiles']]
      nfiles_reco += [i for i in f['nfiles_reco']]
      nevents += [i for i in f['nevents']]
      nevents_reco += [i for i in f['nevents_reco']]

      months_out += [i for i in f['months']]
      days_out += [i for i in f['days']]


  with h5.File(args.o, 'w') as h5f:
    h5f.create_dataset("nfiles", data=nfiles)
    h5f.create_dataset("nevents", data=nevents)
    h5f.create_dataset("months", data=months_out)
    h5f.create_dataset("days", data=days_out)
    h5f.create_dataset("nfiles_reco", data=nfiles_reco)
    h5f.create_dataset("nevents_reco", data=nevents_reco)

def make_dict(base_months, base_days, base_output):
  return {
    (base_months[i], base_days[i]):base_output[i]
    for i in range(len(base_output))
  }

'''def update(args)
  if len(args.files) > 1:
    print('Expect a single file to update with')
    exit(1)

  nfiles = []
  nfiles_reco = []
  nevents = []
  nevents_reco = []
  months_out = []
  days_out = []

  with h5.File(args.i, 'r') as f:
    base_nfiles = [i for i in f['nfiles']]
    base_nfiles_reco = [i for i in f['nfiles_reco']]
    base_nevents = [i for i in f['nevents']]
    base_nevents_reco = [i for i in f['nevents_reco']]

    base_months = [i for i in f['months']]
    base_days = [i for i in f['days']]

  base_nfiles = make_dict(base_months, base_days, base_nfiles)
  base_nfiles_reco = make_dict(base_months, base_days, base_nfiles_reco)
  base_nevents_reco = make_dict(base_months, base_days, base_nevents_reco)
  base_nevents = make_dict(base_months, base_days, base_nevents)

  with open '''

def process_justin(args):

  with open(args.workflows, 'r') as file_in:
    good_wfs_list = [w.strip() for w in file_in.readlines()]
    print(good_wfs_list)

  processed = {}
  all_files = {}
  for n, w in enumerate(good_wfs_list):
    cmd = ['justin', 'show-workflows', '--workflow-id', w]
    print(cmd)
    proc = subprocess.run(cmd, capture_output=True)
    output = proc.stdout.decode('utf-8')
    begin = output.find('(')
    end = output.find(')')
    date = output[begin+1:end].split('--')[0].strip().split('T')[0].replace('-','')
    print(date)

    cmd = ['justin', 'show-files', '--workflow-id', w]
    print(cmd)
    proc = subprocess.run(cmd, capture_output=True)
    states = [
      l.split()[2] for l in proc.stdout.decode('utf-8').split('\n') if len(l.split()) > 2
    ]
    files = [
      l.split()[-1] for l in proc.stdout.decode('utf-8').split('\n') if len(l.split()) > 2
    ]
    print(states.count('processed'), len(states))
    print(date in processed.keys())
    if date not in processed.keys():
      processed[date] = 0
      all_files[date] = []
    processed[date] += states.count('processed')
    all_files[date] += files 
    #if n > 5: break

  results = [
    (int(key[:4]), int(key[4:6]), int(key[6:]), val, len(set(all_files[key])))
    for key, val in processed.items()
  ]

  results.sort(key=operator.itemgetter(1,2))
  print(results)

  with h5.File(args.o, 'w') as h5f:
    h5f.create_dataset("nfiles", data=[i[-1] for i in results])
    #h5f.create_dataset("nevents", data=nevents)
    h5f.create_dataset("months", data=[i[1] for i in results])
    h5f.create_dataset("days", data=[i[2] for i in results])
    h5f.create_dataset("nfiles_reco", data=[i[3] for i in results])
    #h5f.create_dataset("nevents_reco", data=nevents_reco)

def draw(args):
  with h5.File(args.files[0], 'r') as f:
    plt.bar(np.arange(len(f['nfiles'])), f['nfiles'], label='Raw Data', color='orange')
    plt.bar(np.arange(len(f['nfiles'])), f['nfiles_reco'], label='Processed', color='blue')
    plt.xlabel('Days Since 06/19')
    plt.ylabel('Number of Files')
    plt.legend()
    plt.show()

if __name__ == '__main__':
  parser = ap()
  parser.add_argument('-o', type=str, default='prod_nums.h5')
  parser.add_argument('--workflows', '-w', type=str, default=None)
  parser.add_argument('--query', '-q', type=str, default=None)
  parser.add_argument('--month', default=7, type=int)
  parser.add_argument('--days', default=[1], type=int, nargs='+')
  parser.add_argument('routine', type=str, default='process',
                      choices=['process', 'merge', 'process_justin', 'draw'])
  parser.add_argument('--files', '-f', type=str, nargs='+')
  parser.add_argument('--alt', action='store_true')
  args = parser.parse_args()

  routines = {
    'process':process,
    'merge':merge,
    'process_justin':process_justin,
    'draw':draw,
  }
  routines[args.routine](args)

