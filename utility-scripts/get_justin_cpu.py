from metacat.webapi import MetaCatClient
import h5py as h5
from argparse import ArgumentParser as ap
import matplotlib.pyplot as plt


def get_times(args):
  mc = MetaCatClient() 

  cpu_time = {}
  queries = []
  if args.w is not None:
    for w in args.w:
      queries.append(f'files where dune.workflow["workflow_id"] in ({w})'
               ' and dune.output_status=confirmed'
               ' and core.data_tier=full-reconstructed'
              )
  else:
    queries.append(args.q)
  #for w in args.w:
  for query in queries:
    #print(w)
    #query = (f'files where dune.workflow["workflow_id"] in ({w})'
    #         ' and dune.output_status=confirmed'
    #         ' and core.data_tier=full-reconstructed'
    #        )
    if args.limit is not None:
      query += f' limit {str(args.limit)}'

    print(query)
    files = mc.query(query, with_metadata=True)

    for i, f in enumerate(files):
      if i%1000: print(i, end='\r')
      metadata = f['metadata']
      site = metadata['dune.workflow']['site_name']
      cpu_sec = float(metadata['dune.workflow']['jobscript_cpu_seconds'])
      if site not in cpu_time.keys():
        cpu_time[site] = 0.
      cpu_time[site] += cpu_sec 
      if cpu_sec == 0.:
        cpu_time[site] += 1.15*(metadata['core.end_time'] - metadata['core.start_time'])

  print(cpu_time)
  with h5.File(args.o, 'w') as f:
    f.create_dataset('site', data=[i for i in cpu_time.keys()])
    f.create_dataset('cpu_time', data=[i for i in cpu_time.values()])

def plot_from_args(args):
  with h5.File(args.i, 'r') as f:
    plot(f)

def plot(f):
  sites = [i.decode('utf-8') for i in f['site'][:]]
  cpu_times = [i for i in f['cpu_time']]

  country_cpus = {}
  for site, cpu in zip(sites, cpu_times):
    country = site.split('_')[0]
    if country not in country_cpus.keys(): country_cpus[country] = 0.
    country_cpus[country] += cpu 

  country_pct_cpus = { 
    f'{c} {100.*v/sum(country_cpus.values()):.1f}%':v
    for c,v in country_cpus.items()
  }

  fig, ax = plt.subplots()
  ax.pie(country_pct_cpus.values(), labels=country_pct_cpus.keys())
  plt.show()


if __name__ == '__main__':
  parser = ap()
  parser.add_argument('--routine', type=str, default='get_times',
                      choices=['get_times', 'plot'])
  parser.add_argument('-w', type=str, nargs='+', default=None)
  parser.add_argument('-q', type=str, default=None)
  parser.add_argument('--limit', type=int, default=None)
  parser.add_argument('-i', type=str, default=None)
  parser.add_argument('-o', type=str, default=None)
  args = parser.parse_args()

  routines = {
    'get_times':get_times,
    'plot':plot_from_args,
  }

  routines[args.routine](args)
